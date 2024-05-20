public with sharing class CronCalculator {
    // PUBLIC
    public String nextFireCron(Integer delay) {
        Datetime now = Datetime.now();
        Datetime nextTime = now.addSeconds(delay);

        return cronFrom(nextTime);
    }

    // PRIVATE
    private String cronFrom(Datetime dateItem) {
        return dateItem.second() +
            ' ' +
            dateItem.minute() +
            ' ' +
            dateItem.hour() +
            ' ' +
            dateItem.day() +
            ' ' +
            dateItem.month() +
            ' ' +
            '?' +
            ' ' +
            dateItem.year();
    }
}