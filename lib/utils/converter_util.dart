int converterFromInt(String value) => int.parse(value);

int? converterFromIntNull(String? value) => value == null ? null : int.parse(value);

bool converterFromBool(String value) => value == '1' || value.toLowerCase() == 'true';

bool converterFromIntToBool(int value) => value == 1;
