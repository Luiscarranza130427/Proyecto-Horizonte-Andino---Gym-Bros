<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreBannerRequest;
use App\Http\Requests\UpdateBannerRequest;
use App\Http\Resources\BannerResource;
use App\Models\Banner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{DB,Storage};


class BannerController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return BannerResource::collection(Banner::all());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreBannerRequest $request)
    {
        $banner = $this->guardar($request, new Banner());

        return (new BannerResource($banner))->response()->setStatusCode(201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateBannerRequest $request, string $id_banner)
    {
        $banner = Banner::find($id_banner);
        if (! $banner) {
            return response()->json(['message' => 'Banner no encontrado.'], 404);
        }
        $this->guardar($request, $banner);
        return new BannerResource($banner->refresh());
    }

    private function guardar(StoreBannerRequest $request, Banner $banner): Banner
    {
        $ruta = null;
        try {
            $datos = $request->validated();
            if ($request->hasFile('imagen')) {
                $ruta = $request->file('imagen')->store('banners-web', 'public');
                if (! is_string($ruta) || $ruta === '') {
                    throw new \RuntimeException('No se pudo almacenar la imagen del banner.');
                }
                $datos['imagen'] = $ruta;
            }
            DB::transaction(function () use ($banner, $datos) {
                if (! $banner->fill($datos)->save()) {
                    throw new \RuntimeException('No se pudo guardar el banner.');
                }
            });
            return $banner;
        } catch (\Throwable $e) {
            if (is_string($ruta) && $ruta !== '') {
                Storage::disk('public')->delete($ruta);
            }
            throw $e;
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id_banner)
    {
        $banner = Banner::find($id_banner);
        if (! $banner) {
            return response()->json(['message' => 'Banner no encontrado.'], 404);
        }
        $banner->delete();
        return response()->json(['message' => 'Banner eliminado correctamente.']);
    }
}
