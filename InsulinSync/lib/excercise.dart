class ExerciseConstants {
  // Define integer constants for different exercise types.
  static const int EXERCISE_TYPE_BADMINTON = 2;
  static const int EXERCISE_TYPE_BASEBALL = 4;
  static const int EXERCISE_TYPE_BASKETBALL = 5;
  static const int EXERCISE_TYPE_BIKING = 8;
  static const int EXERCISE_TYPE_BIKING_STATIONARY = 9;
  static const int EXERCISE_TYPE_BOOT_CAMP = 10;
  static const int EXERCISE_TYPE_BOXING = 11;
  static const int EXERCISE_TYPE_CALISTHENICS = 13;
  static const int EXERCISE_TYPE_CRICKET = 14;
  static const int EXERCISE_TYPE_DANCING = 16;
  static const int EXERCISE_TYPE_ELLIPTICAL = 25;
  static const int EXERCISE_TYPE_EXERCISE_CLASS = 26;
  static const int EXERCISE_TYPE_FENCING = 27;
  static const int EXERCISE_TYPE_FOOTBALL_AMERICAN = 28;
  static const int EXERCISE_TYPE_FOOTBALL_AUSTRALIAN = 29;
  static const int EXERCISE_TYPE_FRISBEE_DISC = 31;
  static const int EXERCISE_TYPE_GOLF = 32;
  static const int EXERCISE_TYPE_GUIDED_BREATHING = 33;
  static const int EXERCISE_TYPE_GYMNASTICS = 34;
  static const int EXERCISE_TYPE_HANDBALL = 35;
  static const int EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING = 36;
  static const int EXERCISE_TYPE_HIKING = 37;
  static const int EXERCISE_TYPE_ICE_HOCKEY = 38;
  static const int EXERCISE_TYPE_ICE_SKATING = 39;
  static const int EXERCISE_TYPE_MARTIAL_ARTS = 44;
  static const int EXERCISE_TYPE_OTHER_WORKOUT = 0; // Generic workout

  static const int EXERCISE_TYPE_PADDLING = 46;
  static const int EXERCISE_TYPE_PARAGLIDING = 47;
  static const int EXERCISE_TYPE_PILATES = 48;
  static const int EXERCISE_TYPE_RACQUETBALL = 50;
  static const int EXERCISE_TYPE_ROCK_CLIMBING = 51;
  static const int EXERCISE_TYPE_ROLLER_HOCKEY = 52;
  static const int EXERCISE_TYPE_ROWING = 53;
  static const int EXERCISE_TYPE_ROWING_MACHINE = 54;
  static const int EXERCISE_TYPE_RUGBY = 55;
  static const int EXERCISE_TYPE_RUNNING = 56;
  static const int EXERCISE_TYPE_RUNNING_TREADMILL = 57;
  static const int EXERCISE_TYPE_SAILING = 58;
  static const int EXERCISE_TYPE_SCUBA_DIVING = 59;
  static const int EXERCISE_TYPE_SKATING = 60;
  static const int EXERCISE_TYPE_SKIING = 61;
  static const int EXERCISE_TYPE_SNOWBOARDING = 62;
  static const int EXERCISE_TYPE_SNOWSHOEING = 63;
  static const int EXERCISE_TYPE_SOCCER = 64;
  static const int EXERCISE_TYPE_SOFTBALL = 65;
  static const int EXERCISE_TYPE_SQUASH = 66;
  static const int EXERCISE_TYPE_STAIR_CLIMBING = 68;
  static const int EXERCISE_TYPE_STAIR_CLIMBING_MACHINE = 69;
  static const int EXERCISE_TYPE_STRENGTH_TRAINING = 70;
  static const int EXERCISE_TYPE_STRETCHING = 71;
  static const int EXERCISE_TYPE_SURFING = 72;
  static const int EXERCISE_TYPE_SWIMMING_OPEN_WATER = 73;
  static const int EXERCISE_TYPE_SWIMMING_POOL = 74;
  static const int EXERCISE_TYPE_TABLE_TENNIS = 75;
  static const int EXERCISE_TYPE_TENNIS = 76;
  static const int EXERCISE_TYPE_VOLLEYBALL = 78;
  static const int EXERCISE_TYPE_WALKING = 79;
  static const int EXERCISE_TYPE_WATER_POLO = 80;
  static const int EXERCISE_TYPE_WEIGHTLIFTING = 81;
  static const int EXERCISE_TYPE_WHEELCHAIR = 82;
  static const int EXERCISE_TYPE_YOGA = 83;

  static const Map<int, String> exerciseTypeMap = {
    EXERCISE_TYPE_BADMINTON: 'Badminton',
    EXERCISE_TYPE_BASEBALL: 'Baseball',
    EXERCISE_TYPE_BASKETBALL: 'Basketball',
    EXERCISE_TYPE_BIKING: 'Biking',
    EXERCISE_TYPE_BIKING_STATIONARY: 'Biking (Stationary)',
    EXERCISE_TYPE_BOOT_CAMP: 'Boot Camp',
    EXERCISE_TYPE_BOXING: 'Boxing',
    EXERCISE_TYPE_CALISTHENICS: 'Calisthenics',
    EXERCISE_TYPE_CRICKET: 'Cricket',
    EXERCISE_TYPE_DANCING: 'Dancing',
    EXERCISE_TYPE_ELLIPTICAL: 'Elliptical',
    EXERCISE_TYPE_EXERCISE_CLASS: 'Exercise Class',
    EXERCISE_TYPE_FENCING: 'Fencing',
    EXERCISE_TYPE_FOOTBALL_AMERICAN: 'American Football',
    EXERCISE_TYPE_FOOTBALL_AUSTRALIAN: 'Australian Football',
    EXERCISE_TYPE_FRISBEE_DISC: 'Frisbee Disc',
    EXERCISE_TYPE_GOLF: 'Golf',
    EXERCISE_TYPE_GUIDED_BREATHING: 'Guided Breathing',
    EXERCISE_TYPE_GYMNASTICS: 'Gymnastics',
    EXERCISE_TYPE_HANDBALL: 'Handball',
    EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING:
        'High-Intensity Interval Training',
    EXERCISE_TYPE_HIKING: 'Hiking',
    EXERCISE_TYPE_ICE_HOCKEY: 'Ice Hockey',
    EXERCISE_TYPE_ICE_SKATING: 'Ice Skating',
    EXERCISE_TYPE_MARTIAL_ARTS: 'Martial Arts',
    EXERCISE_TYPE_OTHER_WORKOUT: 'Other Workout',
    EXERCISE_TYPE_PADDLING: 'Paddling',
    EXERCISE_TYPE_PARAGLIDING: 'Paragliding',
    EXERCISE_TYPE_PILATES: 'Pilates',
    EXERCISE_TYPE_RACQUETBALL: 'Racquetball',
    EXERCISE_TYPE_ROCK_CLIMBING: 'Rock Climbing',
    EXERCISE_TYPE_ROLLER_HOCKEY: 'Roller Hockey',
    EXERCISE_TYPE_ROWING: 'Rowing',
    EXERCISE_TYPE_ROWING_MACHINE: 'Rowing Machine',
    EXERCISE_TYPE_RUGBY: 'Rugby',
    EXERCISE_TYPE_RUNNING: 'Running',
    EXERCISE_TYPE_RUNNING_TREADMILL: 'Running (Treadmill)',
    EXERCISE_TYPE_SAILING: 'Sailing',
    EXERCISE_TYPE_SCUBA_DIVING: 'Scuba Diving',
    EXERCISE_TYPE_SKATING: 'Skating',
    EXERCISE_TYPE_SKIING: 'Skiing',
    EXERCISE_TYPE_SNOWBOARDING: 'Snowboarding',
    EXERCISE_TYPE_SNOWSHOEING: 'Snowshoeing',
    EXERCISE_TYPE_SOCCER: 'Soccer',
    EXERCISE_TYPE_SOFTBALL: 'Softball',
    EXERCISE_TYPE_SQUASH: 'Squash',
    EXERCISE_TYPE_STAIR_CLIMBING: 'Stair Climbing',
    EXERCISE_TYPE_STAIR_CLIMBING_MACHINE: 'Stair Climbing Machine',
    EXERCISE_TYPE_STRENGTH_TRAINING: 'Strength Training',
    EXERCISE_TYPE_STRETCHING: 'Stretching',
    EXERCISE_TYPE_SURFING: 'Surfing',
    EXERCISE_TYPE_SWIMMING_OPEN_WATER: 'Swimming (Open Water)',
    EXERCISE_TYPE_SWIMMING_POOL: 'Swimming (Pool)',
    EXERCISE_TYPE_TABLE_TENNIS: 'Table Tennis',
    EXERCISE_TYPE_TENNIS: 'Tennis',
    EXERCISE_TYPE_VOLLEYBALL: 'Volleyball',
    EXERCISE_TYPE_WALKING: 'Walking',
    EXERCISE_TYPE_WATER_POLO: 'Water Polo',
    EXERCISE_TYPE_WEIGHTLIFTING: 'Weightlifting',
    EXERCISE_TYPE_WHEELCHAIR: 'Wheelchair',
    EXERCISE_TYPE_YOGA: 'Yoga',
  };

  // Method to get exercise type string from its constant
  static String getExerciseTypeString(int exerciseType) {
    return exerciseTypeMap[exerciseType] ?? 'Unknown Exercise';
  }
}
