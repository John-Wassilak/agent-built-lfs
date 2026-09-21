// Loader for ../../firefox.cfg (this overlay's companion file). Firefox reads
// every .js in <installdir>/defaults/pref/ at startup, before any profile, so
// this is the only place a pref can be set for all profiles and all users
// without owning a profile directory.
//
// obscure_value 0 means firefox.cfg is plain text rather than the historical
// ROT-13 obfuscation Netscape used; without it the file is read as scrambled
// and silently ignored.
pref("general.config.filename", "firefox.cfg");
pref("general.config.obscure_value", 0);
