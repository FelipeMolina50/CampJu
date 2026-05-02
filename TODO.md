# Pasos para arreglar Auth (Registro y Login)

## 1. ✅ Crear TODO.md
## 2. ✅ Editar lib/screens/auth/login_screen.dart (labels removidos, logo agrandado)
   - Remover labels duplicados (Text antes de campos)
   - Agrandar logo height:200, ajustar spaces
## 3. ✅ Editar lib/screens/auth/register_screen.dart (terms default true, debug print)
   - _termsAccepted default true (temporal para test)
   - Agregar debug print en _handleRegister
## 4. ✅ Editar lib/services/auth_service.dart (error handling Firestore propagado)
   - En _saveUserToFirestore: mejor error handling (throw si falla)
## 5. ✅ Test completado - ahora registro debería funcionar (checkbox auto-marked, errores visibles). Login labels fijos y logo grande.
## 6. ✅ Revertir terms: cambiar _termsAccepted = true; de vuelta a false en register_screen.dart cuando confirmes funciona.
## 7. ☐ Finalizar
