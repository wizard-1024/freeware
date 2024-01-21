/'
	fbgetopt.bi - getopt wrapper for FreeBASIC

	Copyright 2016  David Riley <davidjriley1987@gmail.com>


	This program is free software. It comes without any warranty, to
	the extent permitted by applicable law. You can redistribute it
	and/or modify it under the terms of the Do What The #%$@ You Want
	To Public License, Version 2, as published by Sam Hocevar. See
	http://www.wtfpl.net/ for more details.
'/

/'
	Quickstart:
	
	fbgetopt provides access to the C runtime's getopt functonality for 
	processing command-line arguments to your program in a simple, clean 
	way that follows BASIC idioms.  It provides three functions:
	
	Constants:
	
	No_Argument: Used with Options type to denote option takes no 
	argument.
	  
	Required_Argument: Used with Options type to denote option takes a
	required argument.
	  
	Optional_Argument: Used with Options type to denote option can
	optionally take an argument.
	  
	EndOfOptions: Returned by GetOpt*() functions after the last
	option has been processed.
	  
	FlagSet: Returned by GetOpt*() functions when an option is found 
	that sets a flag.
	  
	OptionsError: Returned by GetOpt*() functions when an unknown option
	character is found or when an argument is not found for options 
	requiring one.
	
	ArgumentError: When ShortOpts string starts with a colon 
	ArgumentError is returned by GetOpt*() function to denote a missing
	argument for an option with a required argument. 
	
	Variables:
	
	ArgCount: A direct copy of __FB_ARGC__ to allow it to be accessed
	from outside the global namespace.  fbgetopt provides the 
	ParamCount() function to access the number of commandline options
	without counting the program name itself.
	
	ArgVector: A direct copy of __FB_ARGV__.  fbgetopt provides the
	ParamStr() function to provide access to a programs arguments in 
	a convenient fbstring form.
	
	OptArg: Will be loaded with an option's argument for options that 
	accept arguments.
	
	OptErr: If this variable is nonzero then getopt will print an error
	message if it encounters an unknown option character or an option
	with missing required argument.  This is default behavior.  Set this
	variable to zero if you would prefer getopt prints no message.
	
	OptInd: Returns the optionss position relative to ArgumentCount 
	(__FB_ARGC__).  If no more optionss are found OptInd is loaded 
	with the position of the first non-option argument.
	
	OptOpt: When an unknown option or option with missing argument is 
	found it is stored in this variable.
	
	Types:
	
	Options:
	
	Wrapper type for passing options to getopt with user friendly 
	fbstrings and more convenient initialization.  Usually an array of
	the Options type is created, each element containing the details of 
	a single long option.  This array can be zero, one, or any other 
	number based, and it is not necessesary to include an empty element
	at the end as the wrapper will append one for you when passing it to
	the C runtime.
	
	There are two constructors available, the default constructor simply
	initializing all field values to zero for later assignment, and a
	constructor with arguments for all fields allowing easy 
	initialization at declaration.  This gets us around fbc's 
	limitations on initializing strings in user defined types at 
	declaration.
	
	Member fields:
	
	.OptName as string: Long option name
	
	.HasArg as long: Determines whether option takes an argument.  
	No_Argument, Required_Argument, and Optional_Argument constants are
	provided to specify this field.
	
	.Flag as long ptr: A pointer to an long provided by your code
	to be loaded with .Value when that option is encountered.
	
	.Value as long: If .Flag is a null pointer (0), this is the value
	that will be returned upon encountering the option.  If a .Flag 
	pointer is set, the .Value sets the value to store in your flag to
	indicate the option was encountered.
	
	Functions:
	
	ParamCount() as long:
	
	Returns the number of arguments to your program minus the program 
	name.  This can be taken advantage of to write a simple for loop 
	to process remaining options:
	
		for i as long = OptInd to ParamCount
		
	If there are no remaining options OptInd will be greater than 
	ParamCount and the loop will not run.
	
	ParamStr(index as long) as string:
	
	Returns arguments to your program for a given index starting with 1
	for the first argument.
	
	GetOpts(ShortOpts as string) as string:
	
	Takes single character options.  ShortOpts is a string that 
	specifies valid option characters for your program.  A character in
	this string can be followed by a colon (':') to indicate the option
	takes a required argument.  If the option has an argument it is 
	placed in to the OptArg variable.  GetOpts returns a string 
	containing the option character for next commandline option, when no 
	more options are left, the constant EndOfOptions is returned.  If 
	getopt finds a option character not included in ShortOpts string, 
	the OptionsError constant is returned.  If the ShortOpts string
	begins with a colon (':') then ArgumentError is returned.
	
	GetLongOpts(ShortOpts as string, Opts() as Options, _
				byref OptionIndex as long) as string
	
	Accepts GNU-style long options.  ShortOpts follows the same format
	as the GetOpts() function described above and GetLongOpts() handles
	short options in the same manner as GetOpts(). Opts() is an array of
	the Options type described previously.  OptionIndex is an long 
	you provide and is loaded with the options index in Opts() array. If 
	the option sets a flag, GetLongOpts returns the FlagSet constant and 
	Options.Value will be placed in the variable pointed at by 
	Options.Flag.  If Options.Flag is zero, Options.Val is returned.  
	When no more long options are left to process, GetLongOpts will 
	return EndOfOptions and OptInd will be loaded with the index in 
	ParamStr() of the next remaining option.  

	GetLongOpts(ShortOpts as string, Opts() as Options, _
				byref OptionIndex as long) as string
	
	The same as regular GetLongOpts but allows long options to be 
	prefixed with a single "-".
'/

#pragma once

#ifndef _FBGETOPT_BI_
#define _FBGETOPT_BI_

'These need to be in the global namespace so we can use args to main
dim shared ArgCount as long
dim shared ArgVector as zstring ptr ptr
ArgCount = __FB_ARGC__
ArgVector = __FB_ARGV__

'c runtime getopt header
extern "C"
		declare function getopt_ alias "getopt"(byval as long, _
												byval as zstring const ptr ptr, _
												byval as const zstring ptr) as long
												
		extern optarg_ alias "optarg" as zstring ptr
		extern optind as long
		extern opterr as long
		extern optopt_ alias "optopt" as long
		extern optreset as long

		type option_
			name_ as zstring ptr
			has_arg as long
			flag as long ptr
			val_ as long
		end type

		declare function getopt_long(byval as long, _
									 byval as zstring const ptr ptr, _
									 byval as const zstring ptr, _
									 byval as const option_ ptr, _
									 byval as long ptr) as long
									 
		declare function getopt_long_only(byval as long, _
										  byval as zstring const ptr ptr, _
										  byval as const zstring ptr, _
										  byval as const option_ ptr, _
										  byval as long ptr) as long
end extern

namespace fbgetopt

	'FBSTRING versions
	dim shared OptArg as string
	dim shared OptOpt as string

	const No_Argument = 0
	const Required_Argument = 1
	const Optional_Argument = 2
	const EndOfOptions = chr(255)
	const FlagSet = chr(254)
	const OptionsError = chr(63) '?
	const ArgumentError = chr(58) ':

	type Options
	'
		declare constructor()
		declare constructor(byref o as string, byval h as long, _
							byval f as long ptr, byval v as long)
		OptName as string
		HasArg as long
		Flag as long ptr
		Value as long
	end type

	constructor Options()
	'Default constructor, init values to zero for later assignment
		this.OptName = ""
		this.HasArg = 0
		this.Flag = 0
		this.Value = 0
	end constructor

	constructor Options(byref o as string, byval h as long, _
						byval f as long ptr, byval v as long)
	'Initialize all values in constructor to get around no initialization
	'of strings at declaration for UDTs
		this.OptName = o
		this.HasArg = h
		this.Flag = f
		this.Value = v
	end constructor

	declare function ParamCount() as long
	declare function ParaStr(index as long) as string
	declare function GetOpts(ShortOpts as string) as string
	
	declare function GetLongOpts(ShortOpts as string, Opts() as Options, _
								 byref OptionIndex as long) as string
								 
	declare function GetLongOptsOnly(ShortOpts as string, Opts() as Options, _ 
									 byref OptionIndex as long) as string

	function ParamCount() as long
	'Return count of parameters minus program name
		return ArgCount - 1
	end function

	function ParamStr(index as long) as string
	'Return argument to main for given index
		if (index <= ArgCount) and (index >= 0) then
			return *ArgVector[index]
		else
			return ""
		end if
	end function	

	function GetOpts(ShortOpts as string) as string
	'Get short options
		dim c as long
		c = getopt_(ArgCount, ArgVector, ShortOpts)
		'Set fbstring friendly variables
		OptArg = *optarg_
		OptOpt = chr(optopt_)
		if c = -1 then
			return EndOfOptions
		else
			return chr(c)
		end if
	end function

	function GetLongOpts(ShortOpts as string, Opts() as Options, _
						 byref OptionIndex as long) as string
    'Get long options
		dim high as long = ubound(Opts)
		
		'Make sure we have an empty element at the end
		if lbound(Opts) <> 0 then high += 1
		
		'Populate options_ type that is actually passed to crt's getopt
		dim cOpts(lbound(Opts) to high) as option_
		for i as long = lbound(Opts) to high-1
			cOpts(i).name_ = strptr(Opts(i).OptName)
			cOpts(i).has_arg = Opts(i).HasArg
			cOpts(i).flag = Opts(i).Flag
			cOpts(i).val_ = Opts(i).Value
		next i
		cOpts(high).name_ = 0
		cOpts(high).has_arg = 0
		cOpts(high).flag = 0
		cOpts(high).val_ = 0
		
		dim c as long
		c = getopt_long(ArgCount, ArgVector, ShortOpts, _
						@cOpts(lbound(cOpts)), @OptionIndex)
		OptArg = *optarg_
		OptOpt = chr(optopt_)
		if c = -1 then
			return EndOfOptions
		elseif c = 0 then
			return FlagSet
		else
			return chr(c)
		end if
	end function
	
	function GetLongOptsOnly(ShortOpts as string, Opts() as Options, _
							 byref OptionIndex as long) as string
	'Get long options only allows long options prefixed with a single "-"
	'along with the standard "--" prefix.
		dim high as long = ubound(Opts)
		
		'Make sure we have an empty element at the end
		if lbound(Opts) <> 0 then high += 1
		
		'Populate options_ type that is actually passed to crt's getopt
		dim cOpts(lbound(Opts) to high) as option_
		for i as long = lbound(Opts) to high-1
			cOpts(i).name_ = strptr(Opts(i).OptName)
			cOpts(i).has_arg = Opts(i).HasArg
			cOpts(i).flag = Opts(i).Flag
			cOpts(i).val_ = Opts(i).Value
		next i
		cOpts(high).name_ = 0
		cOpts(high).has_arg = 0
		cOpts(high).flag = 0
		cOpts(high).val_ = 0
		
		dim c as long
		c = getopt_long_only(ArgCount, ArgVector, ShortOpts, _
							 @cOpts(lbound(cOpts)), @OptionIndex)
		OptArg = *optarg_
		OptOpt = chr(optopt_)
		if c = -1 then
			return EndOfOptions
		elseif c = 0 then
			return FlagSet
		else
			return chr(c)
		end if
	end function

end namespace

#endif

