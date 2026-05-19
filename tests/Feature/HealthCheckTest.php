<?php

test('api health endpoint returns ok', function () {
    $response = $this->getJson('/api/health');

    $response->assertOk()
        ->assertJson([
            'status' => 'ok',
        ]);
});
