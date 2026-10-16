class AppImages {
  static const List<String> food = [
    'https://images.pexels.com/photos/31142295/pexels-photo-31142295/free-photo-of-delicious-italian-feast-with-pizza-and-pasta.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://images.pexels.com/photos/5908255/pexels-photo-5908255.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://cdn.pixabay.com/photo/2017/08/26/13/32/hamburger-2683042_1280.jpg',
    'https://cdn.pixabay.com/photo/2018/09/17/05/11/burger-3683046_1280.jpg',
    'https://cdn.pixabay.com/photo/2019/12/19/19/40/eating-4706944_640.jpg',
  ];

  /// Restaurant 1 -> image 1, ... restaurant 6 -> image 1 again.
  static String forId(int id) => food[id.abs() % food.length];
}