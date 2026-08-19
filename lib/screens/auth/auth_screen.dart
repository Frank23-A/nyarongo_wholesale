import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/services/auth_service.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';
import 'package:nyarongo_wholesale/utils/enums.dart';

class AuthScreen extends StatefulWidget {
  final void Function({
    required UserRole role,
    required String displayName,
  }) onAuthenticated;

  const AuthScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool isLogin = true;
  bool obscurePassword = true;
  bool _isSubmitting = false;
  bool _isSendingResetEmail = false;
  UserRole selectedRole = UserRole.customer;
  final TextEditingController _nameController =
      TextEditingController(text: 'Nyarongo User');
  final TextEditingController _emailController =
      TextEditingController(text: 'user@nyarongo.com');
  final TextEditingController _passwordController =
      TextEditingController(text: 'Pass*1');
  String? passwordErrorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;

          return Stack(
            children: [
              Column(
                children: const [
                  Expanded(
                    flex: 3,
                    child: ColoredBox(color: Color(0xFF35359A)),
                  ),
                  Expanded(
                    flex: 7,
                    child: ColoredBox(color: Color(0xFFF2F3FF)),
                  ),
                ],
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 24,
                    vertical: isCompact ? 20 : 30,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (isCompact ? 40 : 60),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Container(
                          padding: EdgeInsets.all(isCompact ? 20 : 28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AuthBrand(isCompact: isCompact),
                              const SizedBox(height: 18),
                              Text(
                                isLogin ? 'Sign In' : 'Create Account',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF27496D),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SegmentedButton<bool>(
                                style: ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  side: WidgetStatePropertyAll(
                                    BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                segments: const [
                                  ButtonSegment<bool>(
                                    value: true,
                                    label: Text('Login'),
                                    icon: Icon(Icons.login_rounded),
                                  ),
                                  ButtonSegment<bool>(
                                    value: false,
                                    label: Text('Signup'),
                                    icon: Icon(Icons.person_add_alt_1_rounded),
                                  ),
                                ],
                                selected: {isLogin},
                                onSelectionChanged: (selection) {
                                  setState(() {
                                    isLogin = selection.first;
                                    passwordErrorText = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              if (passwordErrorText != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBFB),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFFF4D4F),
                                    ),
                                  ),
                                  child: Text(
                                    passwordErrorText!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFFD9363E),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                              if (!isLogin) ...[
                                _AuthFieldLabel(
                                  label: 'Full Name',
                                  theme: theme,
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nameController,
                                  decoration: _fieldDecoration(
                                    hintText: 'Enter your full name',
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              _AuthFieldLabel(
                                label: 'Email Address',
                                theme: theme,
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                decoration: _fieldDecoration(
                                  hintText: 'Enter your email address',
                                ),
                              ),
                              const SizedBox(height: 16),
                              _AuthFieldLabel(
                                label: 'Password',
                                theme: theme,
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: obscurePassword,
                                onChanged: (_) {
                                  if (passwordErrorText != null) {
                                    setState(() {
                                      passwordErrorText = null;
                                    });
                                  }
                                },
                                decoration: _fieldDecoration(
                                  hintText: 'Enter your password',
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF607085),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: isLogin
                                    ? TextButton(
                                        onPressed: _isSendingResetEmail
                                            ? null
                                            : _sendPasswordResetEmail,
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF4F6580),
                                          minimumSize: Size.zero,
                                          padding: EdgeInsets.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: theme.textTheme.bodySmall,
                                        ),
                                        child: Text(
                                          _isSendingResetEmail
                                              ? 'Sending reset email...'
                                              : 'Forgot password?',
                                        ),
                                      )
                                    : Text(
                                        'Use 1 uppercase, 1 lowercase, 1 number and 1 special character.',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFF4F6580),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 18),
                              _AuthFieldLabel(
                                label: 'Choose User Role',
                                theme: theme,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: UserRole.values.map((role) {
                                  final isSelected = role == selectedRole;
                                  return ChoiceChip(
                                    label: Text(_roleLabel(role)),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      setState(() => selectedRole = role);
                                    },
                                    selectedColor: _roleColor(role),
                                    backgroundColor: const Color(0xFFF3F5FA),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppConstants.textPrimaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    side: BorderSide(
                                      color: isSelected
                                          ? Colors.transparent
                                          : const Color(0xFFD9E0EA),
                                    ),
                                  );
                                }).toList(growable: false),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                height: 46,
                                child: FilledButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A84F0),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    textStyle:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          isLogin
                                              ? 'Sign In'
                                              : 'Create Account',
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Customers shop, admins manage products and orders, and workers handle deliveries after login.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppConstants.textSecondaryColor,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF98A3B3)),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: Color(0xFFD3D9E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: Color(0xFFD3D9E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: Color(0xFF4A84F0), width: 1.2),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName =
        isLogin ? email.split('@').first : _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        passwordErrorText = 'Enter a valid email address.';
      });
      return;
    }

    if (!isLogin && displayName.isEmpty) {
      setState(() {
        passwordErrorText = 'Enter your full name.';
      });
      return;
    }

    final validationMessage = _validatePassword(password);
    if (validationMessage != null) {
      setState(() {
        passwordErrorText = validationMessage;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      passwordErrorText = null;
    });

    try {
      if (isLogin) {
        await _authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _authService.saveCurrentUserProfile(
          displayName: displayName.isEmpty ? 'Nyarongo User' : displayName,
          role: selectedRole,
        );
      } else {
        await _authService.createAccount(
          email: email,
          password: password,
          displayName: displayName,
          role: selectedRole,
        );
      }

      if (!mounted) {
        return;
      }

      widget.onAuthenticated(
        role: selectedRole,
        displayName: displayName.isEmpty ? 'Nyarongo User' : displayName,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        passwordErrorText = _authErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        passwordErrorText = 'Authentication failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        passwordErrorText =
            'Enter your registered email address before resetting password.';
      });
      return;
    }

    setState(() {
      _isSendingResetEmail = true;
      passwordErrorText = null;
    });

    try {
      await _authService.sendPasswordResetEmail(email);

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        passwordErrorText = _passwordResetErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        passwordErrorText = 'Could not send reset email: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingResetEmail = false;
        });
      }
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'That email is already registered. Try logging in instead.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _passwordResetErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
        return 'No account exists for that email address.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      default:
        return error.message ?? 'Could not send reset email. Please try again.';
    }
  }

  String? _validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters long.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least 1 uppercase letter.';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least 1 lowercase letter.';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least 1 number.';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\];+=~`]').hasMatch(password)) {
      return 'Password must contain at least 1 special character.';
    }

    return null;
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.admin:
        return 'Admin';
      case UserRole.worker:
        return 'Worker';
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return const Color(0xFF4F9B66);
      case UserRole.admin:
        return const Color(0xFFD97B14);
      case UserRole.worker:
        return const Color(0xFF2C79D4);
    }
  }
}

class _AuthFieldLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _AuthFieldLabel({
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: const Color(0xFF334E68),
      ),
    );
  }
}

class _AuthBrand extends StatelessWidget {
  final bool isCompact;

  const _AuthBrand({
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: isCompact ? 64 : 72,
            height: isCompact ? 64 : 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF2E58D6), Color(0xFF35B9E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Nyarongo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E58D6),
                  letterSpacing: 0.2,
                ),
          ),
          Text(
            'Wholesale',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF35B9E8),
                ),
          ),
        ],
      ),
    );
  }
}
