// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Neither the name of the University of Padova (SIGNET lab) nor the
//    names of its contributors may be used to endorse or promote products
//    derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Project: lightlogger
// Author: Giovanni Toso
// Last Update: 2013.12.25

// -- Pins setting --
// Output
const int lighLEDPin = 10;

// Input (Analog)
const int lightSensorPin = A0;

// Variables and constants
const int lightThreshold = 800;
int lightSensorValue = 0;

void setup() {
  // initialize serial communications at 9600 bps:
  Serial.begin(9600);

  // set the digital pins as outputs
  pinMode(lighLEDPin, OUTPUT);
}

void loop() {
  // Read the value
  lightSensorValue = analogRead(lightSensorPin);
  // Wait for the AC-DC conveter
  delay(10);
  // Note: the value is sent to the serial port only if
  // is above a predermined threshold.
  // This is done in order to redure the traffic in output.
  if (lightSensorValue > lightThreshold) {
      // Print to the serial port the value
      Serial.println(lightSensorValue);
      // Turn on the LED
      digitalWrite(lighLEDPin, HIGH);
  } else {
      // Turn off the LED
      digitalWrite(lighLEDPin, LOW);
  }
}

