
#include <Servo.h>

Servo servos[5];

const int servoPins[5] = {8, 9, 10, 11, 12};
const int SERVO_COUNT = 5;

void setup() {
  Serial.begin(9600);

  for (int i = 0; i < SERVO_COUNT; i++) {
    servos[i].attach(servoPins[i]);
    servos[i].write(0);
  }

  Serial.println("Ready! Send commands like A45, B120, C0");
}

void loop() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    command.toUpperCase();

    if (command.length() < 2) {
      return;
    }

    char servoName = command.charAt(0);
    int servoIndex = servoName - 'A';

    if (servoIndex < 0 || servoIndex >= SERVO_COUNT) {
      Serial.println("ERROR: Invalid servo");
      return;
    }

    String angleText = command.substring(1);

    // Make sure the angle contains only digits
    for (int i = 0; i < angleText.length(); i++) {
      if (!isDigit(angleText.charAt(i))) {
        Serial.println("ERROR: Invalid angle");
        return;
      }
    }

    int angle = angleText.toInt();

    if (angle < 0 || angle > 180) {
      Serial.println("ERROR: Angle must be 0-180");
      return;
    }

    servos[servoIndex].write(angle);

    Serial.print("Servo ");
    Serial.print(servoName);
    Serial.print(" -> ");
    Serial.print(angle);
    Serial.println(" degrees");
  }
}
