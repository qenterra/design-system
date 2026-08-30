VStack {
  HStack {
    Text(1234.56, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
    Text(0.874, format: .percent)
    Text(3.14159, format: .number.precision(.fractionLength(2)))
    Text(9876543, format: .number.grouping(.automatic))
    Text(6.022e23, format: .number.notation(.scientific))
  }
  HStack {
    Text(Measurement(value: 123.45, unit: UnitLength.meters), format: .measurement(width: .wide))
    Text(Measurement(value: 70.0, unit: UnitMass.kilograms), format: .measurement(width: .narrow))
    Text(Measurement(value: 25.5, unit: UnitTemperature.celsius), format: .measurement(width: .abbreviated))
    Text(Measurement(value: -30.1, unit: UnitTemperature.celsius), format: .measurement(width: .wide))
  }
  HStack {
    Text(Date(), format: .dateTime.hour().minute().second())
    Text(Date(), format: .dateTime.day().month().year())

    Text(Duration.seconds(3800), format: .time(pattern: .hourMinute))
    Text(Duration.seconds(91), format: .time(pattern: .minuteSecond))
  }
}