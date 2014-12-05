

// To disable debug logging (all but errors), comment out the following line or change its value to 0
#define Enable_Debug_Logging			1


#if DEBUG
	#if Enable_Debug_Logging
		#define DBDBLog(args...)    NSLog( @"%@", [NSString stringWithFormat: args] )
	#else
		#define DBDBLog(args...)    // do nothing.
	#endif
#else
// DEBUG not defined:
	#define DBDBLog(args...)    // do nothing.
#endif
