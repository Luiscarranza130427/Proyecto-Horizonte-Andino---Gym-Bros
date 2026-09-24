<?php

namespace App\Http\Controllers;

use App\Http\Resources\EjercicioGrupoMuscularResource;
use App\Models\EjercicioGrupoMuscular;


class EjercicioGrupoMuscularController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return EjercicioGrupoMuscularResource::collection(EjercicioGrupoMuscular::all());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
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
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
