import 'package:flutter/material.dart';
import 'package:aulacheck/src/services/datos.dart';
import 'package:aulacheck/src/pages/profesor/cruds/carreras_page.dart';
import 'package:aulacheck/src/config/app_theme.dart';
import 'package:aulacheck/src/widgets/layout_base.dart';

// Si el profesor no inició sesión muestra el login (o el registro).
// Si ya inició sesión muestra su panel.
class ProfessorPage extends StatefulWidget {
  const ProfessorPage({super.key});

  @override
  State<ProfessorPage> createState() => _ProfessorPageState();
}

class _ProfessorPageState extends State<ProfessorPage> {
  bool esRegistro = false; // false = iniciar sesión, true = crear cuenta
  bool cargando = false;
  bool ocultarContrasena = true;

  final TextEditingController ctrlNombre = TextEditingController();
  final TextEditingController ctrlDni = TextEditingController();
  final TextEditingController ctrlEmail = TextEditingController();
  final TextEditingController ctrlContrasena = TextEditingController();

  @override
  void dispose() {
    ctrlNombre.dispose();
    ctrlDni.dispose();
    ctrlEmail.dispose();
    ctrlContrasena.dispose();
    super.dispose();
  }

  void mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> enviar() async {
    final email = ctrlEmail.text.trim();
    final contrasena = ctrlContrasena.text;

    if (email.isEmpty || contrasena.isEmpty) {
      mostrarMensaje('Completá el email y la contraseña');
      return;
    }
    if (esRegistro &&
        (ctrlNombre.text.trim().isEmpty || ctrlDni.text.trim().isEmpty)) {
      mostrarMensaje('Completá tu nombre y DNI');
      return;
    }

    setState(() => cargando = true);
    try {
      if (esRegistro) {
        await Datos.registrarProfesor(
          nombre: ctrlNombre.text.trim(),
          dni: ctrlDni.text.trim(),
          email: email,
          contrasena: contrasena,
        );
      } else {
        await Datos.iniciarSesion(email, contrasena);
      }
      ctrlContrasena.clear();
    } catch (e) {
      mostrarMensaje(Datos.mensajeError(e));
    }
    if (mounted) setState(() => cargando = false);
  }

  Future<void> cerrarSesion() async {
    await Datos.cerrarSesion();
    if (mounted) setState(() {});
  }

  Future<void> editarPerfil() async {
    final p = Datos.profesor!;
    ctrlNombre.text = p.nombre;
    ctrlDni.text = p.dni;

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar mis datos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrlNombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrlDni,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'DNI'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (guardar != true) return;
    if (ctrlNombre.text.trim().isEmpty || ctrlDni.text.trim().isEmpty) return;

    try {
      await Datos.actualizarPerfil(ctrlNombre.text.trim(), ctrlDni.text.trim());
    } catch (e) {
      mostrarMensaje(Datos.mensajeError(e));
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: aulaAppBar(context, 'Panel Docente'),
      body: Datos.profesor == null ? formularioSesion() : panelDocente(),
    );
  }

  Widget formularioSesion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            esRegistro ? 'Crear cuenta de profesor' : 'Iniciar sesión',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            esRegistro
                ? 'Con esta cuenta recuperás tus materias en cualquier celular.'
                : 'Entrá con tu email y contraseña.',
            style: TextStyle(color: context.textoSuave),
          ),
          const SizedBox(height: 24),
          // Nombre y DNI solo se piden al crear la cuenta
          if (esRegistro) ...[
            TextField(
              controller: ctrlNombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrlDni,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'DNI',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: ctrlEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: ctrlContrasena,
            obscureText: ocultarContrasena,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              helperText: esRegistro ? 'Mínimo 6 caracteres' : null,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  ocultarContrasena ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => ocultarContrasena = !ocultarContrasena),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: cargando ? null : enviar,
            child: cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(esRegistro ? 'Crear cuenta' : 'Entrar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => esRegistro = !esRegistro),
            child: Text(
              esRegistro
                  ? '¿Ya tenés cuenta? Iniciá sesión'
                  : '¿No tenés cuenta? Creá una',
            ),
          ),
        ],
      ),
    );
  }

  Widget panelDocente() {
    final p = Datos.profesor!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.violeta,
                    child: Text(
                      iniciales(p.nombre),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DNI ${p.dni}',
                          style: TextStyle(color: context.textoSuave),
                        ),
                        Text(
                          p.email,
                          style: TextStyle(color: context.textoSuave),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar mis datos',
                    onPressed: editarPerfil,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.menu_book),
            label: const Text('Ver Mis Carreras y Materias'),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CarrerasPage()),
              );
              // Por si cerró sesión desde Ajustes
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            onPressed: cerrarSesion,
          ),
        ],
      ),
    );
  }
}
