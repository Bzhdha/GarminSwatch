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

    // Palette — inspirée Swatch : noir, blanc, accent rouge vif
    private const COLOR_BG      = 0x000000;
    private const COLOR_WHITE   = 0xFFFFFF;
    private const COLOR_ACCENT  = 0xFF2020;  // rouge Swatch
    private const COLOR_DIM     = 0x666666;

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
        _drawAccentBar(dc);
        _drawTime(dc, clockTime);
        _drawDate(dc, now);
        _drawBattery(dc, stats.battery);
        _drawSteps(dc);
        _drawHeartRate(dc);
    }

    function onHide() as Void {
    }

    // ── Fond plein noir ──────────────────────────────────────────────────────
    private function _drawBackground(dc as Dc) as Void {
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.fillRectangle(0, 0, _screenWidth, _screenHeight);
    }

    // ── Barre d'accent rouge horizontale (style Swatch) ──────────────────────
    private function _drawAccentBar(dc as Dc) as Void {
        var barY = _centerY + 28;
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(_centerX - 55, barY, 110, 3);
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
            _centerY - 20,
            Graphics.FONT_NUMBER_THAI_HOT,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
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
            _centerY + 50,
            Graphics.FONT_SMALL,
            dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // ── Batterie (icône + % en bas à gauche) ─────────────────────────────────
    private function _drawBattery(dc as Dc, battery as Float) as Void {
        var x   = _centerX - 55;
        var y   = _screenHeight - 35;
        var pct = battery.toNumber();

        var barColor = pct > 20 ? COLOR_ACCENT : 0xFF6600;

        // Contour batterie
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, 22, 11);
        dc.fillRectangle(x + 22, y + 3, 3, 5);

        // Remplissage
        var fill = (18 * pct / 100).toNumber();
        dc.setColor(barColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 2, y + 2, fill, 7);

        // Texte
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x + 28,
            y + 5,
            Graphics.FONT_XTINY,
            pct.format("%d") + "%",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // ── Pas (bas à droite) ───────────────────────────────────────────────────
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

    // ── Fréquence cardiaque (haut) ───────────────────────────────────────────
    private function _drawHeartRate(dc as Dc) as Void {
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo == null || activityInfo.currentHeartRate == null) {
            return;
        }

        var hr = activityInfo.currentHeartRate;

        dc.setColor(COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX,
            35,
            Graphics.FONT_SMALL,
            "♥ " + hr.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
