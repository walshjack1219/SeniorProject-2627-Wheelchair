// --- Motor Specs & Dimensions (DFRobot FIT0450) ---
// 120:1 gear ratio * 16 pulses per single round = 1920 counts/rev
const float COUNTS_PER_REV = 1920.0; 
const float WHEEL_DIAMETER_CM = 6.5; // Update to your wheel's outer diameter
const float WHEEL_CIRCUMFERENCE_CM = WHEEL_DIAMETER_CM * PI;

// --- Front Driver (Driver 1) ---
const int FL_EN = 6;  const int FL_IN1 = 26; const int FL_IN2 = 28; // Front-Left
const int FR_EN = 7;  const int FR_IN1 = 30; const int FR_IN2 = 32; // Front-Right

// --- Rear Driver (Driver 2) ---
const int RL_EN = 8;  const int RL_IN1 = 27; const int RL_IN2 = 29; // Rear-Left
const int RR_EN = 9;  const int RR_IN1 = 31; const int RR_IN2 = 33; // Rear-Right

// --- Encoder Pins (Hardware Interrupts on Channel A) ---
const int ENC_FL_A = 2;   const int ENC_FL_B = 22;
const int ENC_FR_A = 3;   const int ENC_FR_B = 23;
const int ENC_RL_A = 18;  const int ENC_RL_B = 24;
const int ENC_RR_A = 19;  const int ENC_RR_B = 25;

// --- Joystick Pins & Config ---
const int JOY_X_PIN = A0;  // Steering
const int JOY_Y_PIN = A1;  // Throttle
const int JOY_SW_PIN = 4;  // Pushbutton Click (E-Stop)

const int JOY_DEADZONE = 40; // Neutral zone around center (512 +/- 40)
bool estopActive = false;
bool lastButtonState = HIGH;
unsigned long lastDebounceTime = 0;

// Volatile counters for ISRs
volatile long count_FL = 0;
volatile long count_FR = 0;
volatile long count_RL = 0;
volatile long count_RR = 0;

unsigned long lastTelemetryTime = 0;

void setup() {
  Serial.begin(115200);

  // Motor Driver Outputs
  pinMode(FL_EN, OUTPUT); pinMode(FL_IN1, OUTPUT); pinMode(FL_IN2, OUTPUT);
  pinMode(FR_EN, OUTPUT); pinMode(FR_IN1, OUTPUT); pinMode(FR_IN2, OUTPUT);
  pinMode(RL_EN, OUTPUT); pinMode(RL_IN1, OUTPUT); pinMode(RL_IN2, OUTPUT);
  pinMode(RR_EN, OUTPUT); pinMode(RR_IN1, OUTPUT); pinMode(RR_IN2, OUTPUT);

  // Encoder Inputs with internal pull-ups
  pinMode(ENC_FL_A, INPUT_PULLUP); pinMode(ENC_FL_B, INPUT_PULLUP);
  pinMode(ENC_FR_A, INPUT_PULLUP); pinMode(ENC_FR_B, INPUT_PULLUP);
  pinMode(ENC_RL_A, INPUT_PULLUP); pinMode(ENC_RL_B, INPUT_PULLUP);
  pinMode(ENC_RR_A, INPUT_PULLUP); pinMode(ENC_RR_B, INPUT_PULLUP);

  // Joystick Switch Input with internal pull-up
  pinMode(JOY_SW_PIN, INPUT_PULLUP);

  // Attach Interrupts on Mega hardware interrupt pins
  attachInterrupt(digitalPinToInterrupt(ENC_FL_A), isr_FL, RISING);
  attachInterrupt(digitalPinToInterrupt(ENC_FR_A), isr_FR, RISING);
  attachInterrupt(digitalPinToInterrupt(ENC_RL_A), isr_RL, RISING);
  attachInterrupt(digitalPinToInterrupt(ENC_RR_A), isr_RR, RISING);
}

void loop() {
  handleJoystickButton();

  if (estopActive) {
    tankDrive(0, 0);
  } else {
    // Read raw analog values (0 to 1023, center is ~512)
    int rawX = analogRead(JOY_X_PIN);
    int rawY = analogRead(JOY_Y_PIN);

    // Convert to centered offsets (-512 to +512)
    int throttleOffset = (rawY - 512); 
    int steeringOffset = (rawX - 512);

    // Deadzone suppression to prevent motor whine when resting
    int throttle = 0;
    int steering = 0;

    if (abs(throttleOffset) > JOY_DEADZONE) {
      throttle = map(throttleOffset, -512, 512, -255, 255);
    }
    if (abs(steeringOffset) > JOY_DEADZONE) {
      steering = map(steeringOffset, -512, 512, -200, 200);
    }

    // Arcade-to-Tank Drive Mixer
    int leftSpeed  = throttle + steering;
    int rightSpeed = throttle - steering;

    tankDrive(leftSpeed, rightSpeed);
  }

  // Telemetry prints continuously in case a USB monitor is plugged in
  if (millis() - lastTelemetryTime >= 1000) {
    printTelemetry();
    lastTelemetryTime = millis();
  }
}

// --- Joystick Push-Button E-Stop Toggle ---
void handleJoystickButton() {
  int reading = digitalRead(JOY_SW_PIN);
  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > 50) {
    static bool buttonWasPressed = false;
    if (reading == LOW && !buttonWasPressed) {
      estopActive = !estopActive;
      buttonWasPressed = true;
      if (estopActive) {
        tankDrive(0, 0);
        Serial.println(F("*** JOYSTICK E-STOP ENGAGED ***"));
      } else {
        Serial.println(F("*** E-STOP CLEARED - DRIVE ACTIVE ***"));
      }
    } else if (reading == HIGH) {
      buttonWasPressed = false;
    }
  }
  lastButtonState = reading;
}

// --- Tank Drive Execution ---
void tankDrive(int leftSpeed, int rightSpeed) {
  leftSpeed = constrain(leftSpeed, -255, 255);
  rightSpeed = constrain(rightSpeed, -255, 255);

  // Rear axle standard baseline
  setHBridge(RL_EN, RL_IN1, RL_IN2, leftSpeed);
  setHBridge(RR_EN, RR_IN1, RR_IN2, rightSpeed);

  // Front axle: inverted sign & cross-fed speeds
  // This turns forward/back in the correct direction while keeping turning identical
  setHBridge(FL_EN, FL_IN1, FL_IN2, -rightSpeed);
  setHBridge(FR_EN, FR_IN1, FR_IN2, -leftSpeed);
}

// --- Low-Level Direction & PWM Control ---
void setHBridge(int enPin, int in1Pin, int in2Pin, int speed) {
  if (speed > 0) {
    digitalWrite(in1Pin, HIGH);
    digitalWrite(in2Pin, LOW);
    analogWrite(enPin, speed);
  } else if (speed < 0) {
    digitalWrite(in1Pin, LOW);
    digitalWrite(in2Pin, HIGH);
    analogWrite(enPin, abs(speed));
  } else {
    digitalWrite(in1Pin, LOW);
    digitalWrite(in2Pin, LOW);
    analogWrite(enPin, 0);
  }
}

// --- Quadrature ISRs ---
void isr_FL() { count_FL += (digitalRead(ENC_FL_B) == HIGH) ? 1 : -1; }
void isr_FR() { count_FR += (digitalRead(ENC_FR_B) == HIGH) ? -1 : 1; }
void isr_RL() { count_RL += (digitalRead(ENC_RL_B) == HIGH) ? 1 : -1; }
void isr_RR() { count_RR += (digitalRead(ENC_RR_B) == HIGH) ? -1 : 1; }

// --- Telemetry Display ---
void printTelemetry() {
  noInterrupts();
  long snap_FL = count_FL;
  long snap_FR = count_FR;
  long snap_RL = count_RL;
  long snap_RR = count_RR;
  interrupts();

  long counts[4] = {snap_FL, snap_FR, snap_RL, snap_RR};
  const char* labels[4] = {"Front-Left ", "Front-Right", "Rear-Left  ", "Rear-Right "};

  Serial.println(F("\n================= TELEMETRY ================="));
  for (int i = 0; i < 4; i++) {
    float rotations = counts[i] / COUNTS_PER_REV;
    float distanceCm = rotations * WHEEL_CIRCUMFERENCE_CM;

    Serial.print(labels[i]);
    Serial.print(F(" | Pulses: "));
    Serial.print(counts[i]);
    Serial.print(F(" | Rotations: "));
    Serial.print(rotations, 2);
    Serial.print(F(" | Distance: "));
    Serial.print(distanceCm, 2);
    Serial.println(F(" cm"));
  }
  if (estopActive) {
    Serial.println(F("STATUS: [E-STOP ENGAGED - CLICK JOYSTICK TO RESUME]"));
  }
  Serial.println(F("============================================="));
}
