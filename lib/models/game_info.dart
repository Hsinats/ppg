class GameInfo {
  int heartRate = 0;
  int hRV = 0;
  int time = 0;
  int score = 0;

  GameInfo();

  update({newHeartRate, newHRV, newTime, newScore}) {
    if (newHeartRate != null) heartRate = newHeartRate;
    if (newHRV != null) hRV = newHRV;
    if (newTime != null) time = newTime;
    if (newScore != null) score = newScore;
  }
}
