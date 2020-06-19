List<T> slice<T>(List<T> list, [int start = 0, int stop = -1, int step = 1]) {
  stop = stop % list.length;
  var sliced = <T>[];
  for (var i = start; i <= stop; i += step) sliced.add(list[i]);
  return sliced;
}
