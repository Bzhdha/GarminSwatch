import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Time.Gregorian;

class GarminSwatchView extends WatchUi.WatchFace {

    private var _screenWidth  as Number = 260;
    private var _screenHeight as Number = 260;
    private var _centerX      as Number = 130;
    private var _centerY      as Number = 130;

    // Palette
    private const COLOR_BG      = 0x000000;
    private const COLOR_WHITE   = 0xFFFFFF;
    private const COLOR_ACCENT  = 0xFF2020;  // rouge Swatch
    private const COLOR_DIM     = 0x666666;
    private const COLOR_BODY    = 0x00AAFF;  // bleu body battery
    private const COLOR_GREEN   = 0x00CC44;  // productif / peaking
    private const COLOR_ORANGE  = 0xFF8800;  // maintien / surmenage léger
    private const COLOR_BLUE    = 0x4488FF;  // récupération

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _screenWidth  = dc.getWidth();
        _screenHeight = dc.getHeight();
        _centerX      = _screenWidth  / 2;
        _centerY      = _screenHeight / 2;
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setAntiAlias(true);

        var clockTime = System.getClockTime();
        var now       = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var stats     = System.getSystemStats();

        _drawBackground(dc);
        _drawHeartRate(dc);
        _drawBodyBattery(dc);
        _drawTime(dc, clockTime);
        _drawAccentBar(dc);
        _drawDate(dc, now);
        _drawTrainingStatus(dc);
        _drawVo2Max(dc);
        _drawBattery(dc, stats.battery);
        _drawSteps(dc);
    }

    function onHide() as Void {
    }

    // ── Fond plein noir ──────────────────────────────────────────────────────
    private function _drawBackground(dc as Dc) as Void {
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.fillRectangle(0, 0, _screenWidth, _screenHeight);
    }

    // ── Fréquence cardiaque (haut gauche) ────────────────────────────────────
    private function _drawHeartRate(dc as Dc) as Void {
        var actInfo = Activity.getActivityInfo();
        if (actInfo == null || actInfo.currentHeartRate == null) {
            return;
        }
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX / 2,
            32,
            Graphics.FONT_SMALL,
            "♥ " + actInfo.currentHeartRate.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // ── Body Battery (haut droite) ───────────────────────────────────────────
    private function _drawBodyBattery(dc as Dc) as Void {
        var info = ActivityMonitor.getInfo();
        if (info == null || !(info has :bodyBatteryLevel)) {
            return;
        }
        var bb = info[:bodyBatteryLevel];
        if (bb == null) {
            return;
        }
        dc.setColor(COLOR_BODY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX + _centerX / 2,
            32,
            Graphics.FONT_SMALL,
            "BB " + bb.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // ── Heure HH:MM ──────────────────────────────────────────────────────────
    private function _drawTime(dc as Dc, clockTime as ClockTime) as Void {
        var hour   = clockTime.hour;
        var minute = clockTime.min;

        if (!System.getDeviceSettings().is24Hour) {
            if (hour > 12) { hour -= 12; }
            if (hour == 0) { hour  = 12; }
        }

        var timeStr = hour.format("%02d") + ":" + minute.format("%02d");

        dc.setColor(COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX,
            _centerY - 18,
            Graphics.FONT_NUMBER_THAI_HOT,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // ── Barre d'accent rouge horizontale (style Swatch) ──────────────────────
    private function _drawAccentBar(dc as Dc) as Void {
        var barY = _centerY + 30;
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(_centerX - 55, barY, 110, 3);
    }

    // ── Date : Lun. 24 mai ───────────────────────────────────────────────────
    private function _drawDate(dc as Dc, now as Gregorian.Info) as Void {
        var days   = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"];
        var months = ["jan", "fév", "mar", "avr", "mai", "jun",
                      "jul", "aoû", "sep", "oct", "nov", "déc"];

        var dateStr = days[now.day_of_week - 1] + ". "
                    + now.day.format("%d") + " "
                    + months[now.month - 1];

        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX,
            _centerY + 52,
            Graphics.FONT_SMALL,
            dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // ── Statut d'entraînement — icône triangle colorée ───────────────────────
    // Valeurs : 0=aucun 1=maintien 2=récup 3=improductif
    //           4=productif 5=pic 6=surmenage 7=récup_requise
    private function _drawTrainingStatus(dc as Dc) as Void {
        var info = ActivityMonitor.getInfo();
        if (info == null || !(info has :trainingStatus)) {
            return;
        }
        var status = info[:trainingStatus];
        if (status == null) {
            return;
        }

        var cx  = _centerX - 25;
        var cy  = _screenHeight - 58;
        var w   = 7;   // demi-largeur du triangle
        var h   = 11;  // hauteur du triangle

        var color;
        var up;  // true = triangle pointe en haut, false = en bas

        if (status == 4 || status == 5) {
            color = COLOR_GREEN;
            up = true;
        } else if (status == 1) {
            color = COLOR_ORANGE;
            up = true;
        } else if (status == 2 || status == 7) {
            color = COLOR_BLUE;
            up = false;
        } else if (status == 6) {
            // Surmenage : triangle rouge pointe en bas (alarme)
            color = COLOR_ACCENT;
            up = false;
        } else {
            // Aucun / improductif : barre horizontale grise
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(cx - w, cy - 1, 2 * w, 3);
            return;
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (up) {
            dc.fillPolygon([[cx, cy - h / 2], [cx - w, cy + h / 2], [cx + w, cy + h / 2]]);
        } else {
            dc.fillPolygon([[cx, cy + h / 2], [cx - w, cy - h / 2], [cx + w, cy - h / 2]]);
        }
    }

    // ── VO2 max (à droite du statut d'entraînement) ──────────────────────────
    private function _drawVo2Max(dc as Dc) as Void {
        var info = ActivityMonitor.getInfo();
        if (info == null || !(info has :vo2MaxRunning)) {
            return;
        }
        var vo2 = info[:vo2MaxRunning];
        if (vo2 == null) {
            return;
        }
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX + 10,
            _screenHeight - 58,
            Graphics.FONT_XTINY,
            "VO2 " + vo2.format("%d"),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // ── Batterie montre (bas gauche) ─────────────────────────────────────────
    private function _drawBattery(dc as Dc, battery as Float) as Void {
        var x   = _centerX - 55;
        var y   = _screenHeight - 35;
        var pct = battery.toNumber();

        var barColor = pct > 20 ? COLOR_ACCENT : COLOR_ORANGE;

        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, 22, 11);
        dc.fillRectangle(x + 22, y + 3, 3, 5);

        var fill = (18 * pct / 100).toNumber();
        dc.setColor(barColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 2, y + 2, fill, 7);

        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x + 28,
            y + 5,
            Graphics.FONT_XTINY,
            pct.format("%d") + "%",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // ── Pas cumulés (bas droite) ─────────────────────────────────────────────
    private function _drawSteps(dc as Dc) as Void {
        var info  = ActivityMonitor.getInfo();
        var steps = (info != null && info.steps != null) ? info.steps : 0;

        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX + 30,
            _screenHeight - 30,
            Graphics.FONT_XTINY,
            steps.format("%d") + " pas",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
