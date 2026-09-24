<?php

namespace App\Services\Usuarios;

use Illuminate\Http\UploadedFile;
use Illuminate\Validation\ValidationException;
use OpenSpout\Reader\XLSX\{Reader,Options};
use OpenSpout\Common\Entity\Cell\{FormulaCell,ErrorCell};

class LeerArchivoUsuarios
{
    public const OBLIGATORIAS = ['nombres','apellidos','apodo','genero','correo','tipo_documento','numero_documento','telefono','fecha_nacimiento'];
    public const OPCIONALES = ['direccion','fecha_registro','inicio_suscripcion','fin_suscripcion'];
    public const MAX_FILAS = 200;

    public function leer(UploadedFile $archivo): array
    {
        try {
            $filas = strtolower($archivo->getClientOriginalExtension()) === 'xlsx'
                ? $this->excel($archivo->getRealPath()) : $this->csv($archivo->getRealPath());
            $cabecera = null; $datos = [];
            foreach ($filas as $numero=>$valores) {
                if ($numero > 1000) { $this->error('archivo', 'El archivo contiene demasiadas filas.'); }
                if ($cabecera === null) {
                    $cabecera = array_map(fn ($v) => is_string($v) ? trim(ltrim($v, "\xEF\xBB\xBF")) : '', $valores);
                    $permitidas = array_merge(self::OBLIGATORIAS,self::OPCIONALES);
                    if (count($cabecera) !== count(array_unique($cabecera)) || array_diff($cabecera,$permitidas)
                        || array_diff(self::OBLIGATORIAS,$cabecera)) {
                        $this->error('archivo', 'Encabezados invalidos, repetidos o incompletos. Usa la plantilla de importacion.');
                    }
                    continue;
                }
                if (count(array_filter($valores,fn ($v) => $v !== null && $v !== '')) === 0) { continue; }
                if (count($datos) >= self::MAX_FILAS) { $this->error('archivo', 'Maximo 200 usuarios por archivo.'); }
                if (count($valores) > count($cabecera)) { $this->error("filas.$numero", 'Hay mas celdas que encabezados.'); }
                $valores = array_pad($valores,count($cabecera),null);
                $fila = array_combine($cabecera,$valores);
                foreach ($fila as $campo=>&$valor) {
                    if ($valor instanceof \DateTimeInterface && in_array($campo,['fecha_nacimiento','fecha_registro','inicio_suscripcion','fin_suscripcion'],true)) {
                        $valor = $valor->format('Y-m-d');
                    }
                    if ($valor !== null && !is_string($valor)) {
                        $this->error("filas.$numero.$campo", 'Usa texto para los datos; documento y telefono deben conservar ceros iniciales.');
                    }
                    if (is_string($valor)) {
                        if (! mb_check_encoding($valor,'UTF-8') || preg_match('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/',$valor)) {
                            $this->error("filas.$numero.$campo", 'Usa texto UTF-8 sin caracteres de control.');
                        }
                        $valor = trim($valor);
                        if ($valor === '') { $valor = null; }
                    }
                }
                unset($valor);
                $datos[$numero] = $fila;
            }
            if (!$datos) { $this->error('archivo','El archivo no contiene usuarios.'); }
            return $datos;
        } catch (ValidationException $e) { throw $e; }
        catch (\Throwable) { $this->error('archivo','No se pudo leer el archivo. Usa CSV UTF-8 o un Excel XLSX valido.'); }
    }

    private function csv(string $path): \Generator
    {
        $f = fopen($path,'r');
        try {
            $primera = fgets($f);
            if ($primera === false) { return; }
            $separador = count(str_getcsv($primera,';','"','')) > count(str_getcsv($primera,',','"','')) ? ';' : ',';
            rewind($f); $numero = 0;
            while (($fila = fgetcsv($f,null,$separador,'"','')) !== false) { yield ++$numero => $fila; }
        } finally { fclose($f); }
    }

    private function excel(string $path): array
    {
        $zip = new \ZipArchive();
        if ($zip->open($path) !== true) { $this->error('archivo','Excel XLSX invalido.'); }
        try {
            $total = 0;
            if ($zip->numFiles > 500) { $this->error('archivo','Excel demasiado complejo. Usa la plantilla.'); }
            for ($i=0; $i<$zip->numFiles; $i++) {
                $info = $zip->statIndex($i); $total += $info['size'];
                if ($total > 20*1024*1024 || preg_match('~externalLinks|vbaProject|\.\./~i',$info['name'])) {
                    $this->error('archivo','Excel demasiado grande o con contenido no permitido.');
                }
            }
        } finally { $zip->close(); }
        $options = new Options(); $options->SHOULD_PRESERVE_EMPTY_ROWS = true;
        $reader = new Reader($options);
        $datos = []; $errores = null;
        try {
            $reader->open($path); $hojas = 0;
            foreach ($reader->getSheetIterator() as $sheet) {
                if (++$hojas > 1) { $this->error('archivo','El Excel debe contener una sola hoja.'); }
                foreach ($sheet->getRowIterator() as $numero=>$row) {
                    if ($numero > 1000) { $this->error('archivo','El archivo contiene demasiadas filas.'); }
                    $valores = [];
                    foreach ($row->getCells() as $cell) {
                        if ($cell instanceof FormulaCell || $cell instanceof ErrorCell) {
                            $this->error("filas.$numero",'No se admiten formulas ni celdas con errores.');
                        }
                        $valores[] = $cell->getValue();
                    }
                    $datos[$numero] = $valores;
                }
            }
        } catch (ValidationException $e) {
            $errores = $e->errors();
            unset($e);
        } finally {
            $reader->close();
            unset($row,$sheet,$reader);
            gc_collect_cycles();
        }
        if ($errores) { throw ValidationException::withMessages($errores); }
        return $datos;
    }

    private function error(string $campo, string $mensaje): never
    {
        throw ValidationException::withMessages([$campo=>[$mensaje]]);
    }
}
