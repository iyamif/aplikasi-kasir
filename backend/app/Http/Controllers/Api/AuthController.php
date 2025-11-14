<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Auth;
use SimpleSoftwareIO\QrCode\Facades\QrCode;
use PragmaRX\Google2FALaravel\Support\Authenticator;
use PragmaRX\Google2FAQRCode\Google2FA;
use Illuminate\Support\Facades\Validator;




class AuthController extends Controller
{

    protected $google2fa;

    public function __construct()
    {
        $this->google2fa = app('pragmarx.google2fa');
    }
    

    
    public function register(Request $request)
    {
        try {
            // Validasi manual supaya bisa catch exception
            $validator = Validator::make($request->all(), [
                'name' => 'required|string',
                'email' => 'required|email|unique:users',
                'password' => 'required|string|min:6|confirmed',
            ]);
    
            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Validasi gagal',
                    'errors' => $validator->errors(),
                ], 422);
            }
    
            $validated = $validator->validated();
    
            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
            ]);
    
            return response()->json([
                'status' => 'success',
                'message' => 'User created successfully',
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ], 201);
    
        } catch (\Exception $e) {
            // Menangani semua error lain
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 500);
        }
    }
    

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Email atau password salah'
            ], 401);
        }

        // === CEK apakah user sudah punya secret 2FA ===
        if (!$user->google2fa_secret) {
            // BELUM SETUP → Buat secret baru dan kirim QR code
            $secret = $this->google2fa->generateSecretKey();
            $user->google2fa_secret = $secret;
            $user->is_two_factor_enabled = true;
            $user->save();

            $qrUrl = $this->google2fa->getQRCodeUrl(
                'MyPOSApp',
                $user->email,
                $secret
            );

            return response()->json([
                'status' => 'need_scan',
                'message' => 'Silakan scan QR code di Google Authenticator',
                'user_id' => $user->id,
                'qr_url' => $qrUrl,
                'secret' => $secret,
            ]);
        }

        // SUDAH SETUP 2FA → Kirim status need_otp (Frontend akan tampilkan modal OTP)
        return response()->json([
            'status' => 'need_otp',
            'message' => 'Silakan masukkan kode OTP dari aplikasi Authenticator',
            'user_id' => $user->id,
        ]);
    }

    // === VERIFIKASI OTP ===
    public function verify2FA(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required',
            'otp' => 'required'
        ]);

        $user = User::find($request->user_id);
        if (!$user) {
            return response()->json(['message' => 'User tidak ditemukan'], 404);
        }

        $valid = $this->google2fa->verifyKey($user->google2fa_secret, $request->otp);
        if (!$valid) {
            return response()->json(['message' => 'Kode OTP salah'], 401);
        }

        // Buat token Sanctum
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil',
            'token' => $token,
            'user' => $user,
        ]);
    }

    // === LOGOUT ===
    public function logout(Request $request)
    {
        $user = $request->user();
        if ($user) {
            $user->currentAccessToken()->delete();
        }

        return response()->json(['message' => 'Logout berhasil']);
    }

  

}
