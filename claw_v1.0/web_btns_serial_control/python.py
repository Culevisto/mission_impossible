
from flask import Flask, render_template_string, request, jsonify
import serial
import serial.tools.list_ports
import time
import threading

app = Flask(__name__)

BAUD_RATE = 9600
SERVO_NAMES = ["A", "B", "C", "D", "E"]
servo_angles = {name: 0 for name in SERVO_NAMES}
serial_lock = threading.Lock()

def connect_arduino():
    ports = list(serial.tools.list_ports.comports())

    for port in ports:
        print(f"Found port: {port.device} ({port.description})")

    for port in ports:
        if (
            "Arduino" in port.description
            or "USB Serial" in port.description
            or "ttyACM" in port.device
            or "ttyUSB" in port.device
            or "CH340" in port.description
        ):
            try:
                connection = serial.Serial(
                    port.device,
                    BAUD_RATE,
                    timeout=1
                )
                time.sleep(2)
                print(f"Connected to Arduino: {port.device}")
                return connection
            except serial.SerialException as error:
                print(f"Cannot connect to {port.device}: {error}")

    print("Arduino not found. Simulation mode enabled.")
    return None


arduino = connect_arduino()

HTML_PAGE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ARMAN | Robotic Arm Controller</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            padding: 30px 15px;
            background: #0f172a;
            color: #f8fafc;
            font-family: Arial, sans-serif;
        }

        .container {
            max-width: 850px;
            margin: auto;
        }

        h1 {
            text-align: center;
            margin-bottom: 8px;
        }

        .subtitle {
            text-align: center;
            color: #94a3b8;
            margin-bottom: 30px;
        }

        .card {
            background: #1e293b;
            padding: 24px;
            border-radius: 14px;
            margin-bottom: 18px;
            border: 1px solid #334155;
        }

        .card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .servo-title {
            font-size: 20px;
            font-weight: bold;
        }

        .angle {
            font-size: 24px;
            color: #38bdf8;
            font-weight: bold;
        }

        input[type="range"] {
            width: 100%;
            cursor: pointer;
            accent-color: #38bdf8;
        }

        .range-labels {
            display: flex;
            justify-content: space-between;
            color: #94a3b8;
            font-size: 13px;
            margin-top: 7px;
        }

        .actions {
            display: flex;
            gap: 10px;
            margin-top: 20px;
        }

        button {
            border: none;
            border-radius: 8px;
            padding: 12px 18px;
            cursor: pointer;
            font-weight: bold;
            background: #334155;
            color: white;
            flex: 1;
        }

        button:hover {
            background: #475569;
        }

        .primary {
            background: #0284c7;
        }

        .primary:hover {
            background: #0369a1;
        }

        .global-actions {
            display: flex;
            gap: 12px;
            margin-bottom: 24px;
        }

        .status {
            padding: 16px;
            background: #1e293b;
            border-radius: 10px;
            color: #94a3b8;
            text-align: center;
            margin-top: 25px;
        }

        @media(max-width: 500px) {
            .global-actions {
                flex-direction: column;
            }
        }
    </style>
</head>

<body>
<div class="container">

    <h1>ARMAN</h1>
    <p class="subtitle">Robotic Arm Control System</p>

    <div class="global-actions">
        <button class="primary" onclick="setAll(0)">
            All to 0°
        </button>

        <button onclick="setAll(90)">
            All to 90°
        </button>

        <button onclick="setAll(180)">
            All to 180°
        </button>
    </div>

    <div id="servo-container"></div>

    <div class="status" id="status">
        Waiting for commands...
    </div>

</div>

<script>
    const servos = ["A", "B", "C", "D", "E"];
    const timers = {};
    const container = document.getElementById("servo-container");

    servos.forEach((servo, index) => {
        container.innerHTML += `
            <div class="card">
                <div class="card-header">
                    <span class="servo-title">
                        Servo ${servo} (D${index + 8})
                    </span>
                    <span class="angle" id="angle-${servo}">
                        0°
                    </span>
                </div>

                <input
                    type="range"
                    min="0"
                    max="180"
                    value="0"
                    id="slider-${servo}"
                    oninput="sliderChanged('${servo}', this.value)"
                    onchange="sendAngle('${servo}', this.value)"
                >

                <div class="range-labels">
                    <span>0°</span>
                    <span>90°</span>
                    <span>180°</span>
                </div>

                <div class="actions">
                    <button onclick="setAngle('${servo}', 0)">
                        0°
                    </button>

                    <button onclick="setAngle('${servo}', 90)">
                        90°
                    </button>

                    <button onclick="setAngle('${servo}', 180)">
                        180°
                    </button>
                </div>
            </div>
        `;
    });

    function sliderChanged(servo, angle) {
        document.getElementById(
            `angle-${servo}`
        ).innerText = `${angle}°`;

        clearTimeout(timers[servo]);

        timers[servo] = setTimeout(() => {
            sendAngle(servo, angle);
        }, 150);
    }

    async function sendAngle(servo, angle) {
        clearTimeout(timers[servo]);

        const command = `${servo}${angle}`;

        try {
            const response = await fetch("/control", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({
                    servo: servo,
                    angle: Number(angle)
                })
            });

            const data = await response.json();

            document.getElementById("status").innerText =
                `${command} → ${data.message}`;

        } catch (error) {
            document.getElementById("status").innerText =
                "Connection error";
        }
    }

    function setAngle(servo, angle) {
        document.getElementById(
            `slider-${servo}`
        ).value = angle;

        document.getElementById(
            `angle-${servo}`
        ).innerText = `${angle}°`;

        sendAngle(servo, angle);
    }

    function setAll(angle) {
        servos.forEach(servo => {
            setAngle(servo, angle);
        });
    }
</script>
</body>
</html>
"""


@app.route("/")
def index():
    return render_template_string(HTML_PAGE)



@app.route("/control", methods=["POST"])
def control():
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify(
            status="error",
            message="Invalid JSON"
        ), 400

    servo = data.get("servo")
    angle = data.get("angle")

    if servo not in SERVO_NAMES:
        return jsonify(
            status="error",
            message="Invalid servo"
        ), 400

    if type(angle) is not int or not 0 <= angle <= 180:
        return jsonify(
            status="error",
            message="Angle must be 0-180"
        ), 400

    command = f"{servo}{angle}\n"

    if arduino and arduino.is_open:
        try:
            with serial_lock:
                arduino.write(command.encode("ascii"))
                arduino.flush()

            print(f"Sent to Arduino: {command.strip()}")

            servo_angles[servo] = angle

            return jsonify(
                status="success",
                message=f"Sent {servo}{angle}"
            )

        except serial.SerialException as error:
            return jsonify(
                status="error",
                message=str(error)
            ), 503

    return jsonify(
        status="simulated",
        message=f"Simulation: {servo}{angle}"
    )


if __name__ == "__main__":
    app.run(
        host="127.0.0.1",
        port=5000,
        debug=True,
        use_reloader=False,
        threaded=True
    )
