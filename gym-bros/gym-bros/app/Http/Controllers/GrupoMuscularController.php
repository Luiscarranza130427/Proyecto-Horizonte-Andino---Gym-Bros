<?php

namespace App\Http\Controllers;

use App\Http\Resources\GrupoMuscularResource;
use App\Models\GrupoMuscular;


class GrupoMuscularController extends Controller
{
    public function tipos()
    {
        return response()->json(['data' => GrupoMuscular::select('id', 'tipo')->orderBy('id')->get()]);
    }

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return GrupoMuscularResource::collection(GrupoMuscular::all());
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
