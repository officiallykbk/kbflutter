import 'package:bizorganizer/main.dart';
import 'package:bizorganizer/models/reusables.dart';
import 'package:bizorganizer/providers/loading_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  SignInScreen({super.key});
  @override
  Widget build(BuildContext context) {
    Future<void> login() async {
      try {
        await supabase.auth.signInWithPassword(
            // email: emailController.text, password: passwordController.text);
            email: "me@admin.com",
            password: "SecurePass123!");
      } catch (e) {
        print('Failed to login ${e}');
        CustomSnackBar.show(context, 'Failed to login', 'error');
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.1),
                      SizedBox(
                          height: 100,
                          child:
                              //   CacheImage(
                              //       imageUrl:
                              //           "https://i.postimg.cc/nz0YBQcH/Logo-light.png"),
                              // ),
                              Text('')),
                      SizedBox(height: constraints.maxHeight * 0.1),
                      Text(
                        "Sign In",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                      ),
                      SizedBox(height: constraints.maxHeight * 0.05),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              style: TextStyle(color: Colors.black),
                              controller: emailController,
                              decoration: const InputDecoration(
                                hintText: 'Email',
                                filled: true,
                                fillColor: Color(0xFFF5FCF9),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0 * 1.5, vertical: 16.0),
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50)),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onSaved: (email) {
                                // Save it
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Field can not be empty';
                                } else {
                                  bool isValidEmail(String email) {
                                    final emailRegex = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                    );
                                    return emailRegex.hasMatch(email);
                                  }

                                  if (isValidEmail(emailController.text)) {
                                    return null;
                                  } else {
                                    return 'Invalid Email';
                                  }
                                }
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: TextFormField(
                                style: TextStyle(color: Colors.black),
                                controller: passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  hintText: 'Password',
                                  filled: true,
                                  fillColor: Color(0xFFF5FCF9),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16.0 * 1.5, vertical: 16.0),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(50)),
                                  ),
                                ),
                                onSaved: (passaword) {
                                  // Save it
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password can not be empty';
                                  } else {
                                    return null;
                                  }
                                },
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                context.read<LoadingProvider>().showloading();
                                //                         final loadingProvider =
                                //     Provider.of<LoadingProvider>(context, listen: false);
                                // loadingProvider.showloading();
                                if (_formKey.currentState!.validate()) {
                                  await login();
                                  context.read<LoadingProvider>().hideloading();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFF00BF6D),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text("Sign in"),
                            ),
                            const SizedBox(height: 16.0),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot Password?',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .color!
                                          .withOpacity(0.64),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Consumer<LoadingProvider>(
                builder: (context, loadingModel, child) =>
                    GlobalLoadingIndicator(loadState: loadingModel.isLoading))
          ],
        ),
      ),
    );
  }
}
