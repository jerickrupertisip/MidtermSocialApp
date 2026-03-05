import "dart:ui";
import "package:shadcn_flutter/shadcn_flutter.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = ThemeData.dark(radius: 0.75);
    return ShadcnApp(
      darkTheme: theme,
      theme: theme,
      themeMode: ThemeMode.system,
      scaling: const AdaptiveScaling(0.85),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _Home();
}

class Scroller extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse, // This enables clicking and dragging!
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class _Home extends State<Home> {
  var pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: ScrollConfiguration(
        behavior: Scroller(),
        child: Stack(
          alignment: .center,
          children: [
            PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) {
                var size = MediaQuery.of(context).size;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Theme.of(context).radiusMd,
                        ),
                        child: Image.network(
                          "https://picsum.photos/seed/${index * 40}/${(size.width * 2).toInt()}/${(size.height * 2).toInt()}",
                          fit: BoxFit.cover,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                                if (frame != null) return child;

                                return Container(
                                  color: Colors.black,
                                  alignment: Alignment.center,
                                  child: CircularProgressIndicator(
                                    size: Theme.of(
                                      context,
                                    ).typography.x8Large.fontSize,
                                  ),
                                );
                              },
                        ),
                      ),
                    ),

                    Positioned(
                      child: Container(
                        child: Text(
                          "Hello, World",
                          style: TextStyle(
                            shadows: [
                              Shadow(
                                offset: Offset.fromDirection(10, 2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ).h1,
                      ).withPadding(all: Theme.of(context).radiusXl),
                    ),
                  ],
                );
              },
            ),

            Positioned(
              bottom: 0.0,
              left: 0.0,
              child: Container(
                child: Text(
                  "Hello, World",
                  style: TextStyle(
                    shadows: [
                      Shadow(
                        offset: Offset.fromDirection(10, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ).h1,
              ).withPadding(all: Theme.of(context).radiusXl),
            ),
          ],
        ),
      ),
    ).withPadding(all: Theme.of(context).typography.small.fontSize);
  }
}
