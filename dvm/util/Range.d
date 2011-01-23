/**
 * Copyright: Copyright (c) 2008-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2008
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 * 
 */
module dvm.util.Range;

/**
 * This stucts represents a range with a beginning and an end.
 * The Range only workds with integer types and char types.
 * 
 * Example:
 * ---
 * 		auto r = range[3..9];
 * 
 * 		foreach (i ; r)
 * 			println(i);
 * 
 * 		// will print 3 up to including 8
 * 
 * 		foreach (c ; range['a'..'h'];
 * 			println(c);
 * 
 * 		// will print a up to including g
 * ---
 */
struct Range (T = size_t, U = T)
{
	/// The beginning of the range
	T start;
	
	/// The end of the range
	U end;
	
	/**
	 * Creates a new Range using the following syntax
	 * 
	 * Example:
	 *     $(D_CODE auto r = range[3..9];)
	 * 
	 * Params:
	 *     start = the start of the range
	 *     end = the end of the range
	 *     
	 * Returns: the created Range
	 */
	static Range!(T, U) opSlice (T start, U end)
	{
		Range!(T, U) r;
		r.start = start;
		r.end = end;
		
		return r;
	}
	
	/**
	 * Allows the range to work in a foreach loop
	 * 
	 * Params:
	 *     dg = 
	 * Returns:
	 */
	int opApply(int delegate(ref T) dg)
    {   
		int result = 0;

		for (T i = start; i < end; i++)
		{
		    result = dg(i);
		    
		    if (result)
		    	break;
		}
		
		return result;
    }
	
	/**
	 * Allows the range to work in a foreach_reverse loop
	 * 
	 * Params:
	 *     dg = 
	 * Returns:
	 */
	int opApplyReverse(int delegate(ref T) dg)
    {   
		int result = 0;

		for (T i = end - 1; i >= start; i--)
		{
		    result = dg(i);
		    
		    if (result)
		    	break;
		}
		
		return result;
    }
	
	/**
	 * Creates an array of the Range
	 * 
	 * Returns: the created array
	 * See_Also: opCall
	 * See_Also: opSlice
	 */
	T[] toArr ()
	{
		T[] arr;
		arr.length = end - start;
		size_t index = 0;
		T s = start;
		
		for (size_t i = start; i < end; i++)
			arr[index++] = s++;
		
		return arr;
	}
	
	/**
	 * Creates an array of the Range
	 * 
	 * Returns: the created array
	 * See_Also: toArr
	 * See_Also: opSlice
	 */
	T[] opCall ()
	{
		return toArr;
	}
	
	/**
	 * Creates an array of the Range
	 * 
	 * Returns: the created array
	 * See_Also: toArr
	 * See_Also: opCall
	 */
	T[] opSlice ()
	{
		return toArr;
	}
	
	/**
	 * Returns the element at the specified index
	 * 
	 * Params:
	 *     index = the index of the element
	 *     
	 * Returns: the element at the specified index
	 */
	T opIndex (T index)
	in
	{
		assert(index >= 0 && index <= (end - start) - 1);
	}
	body
	{
		if (index == 0)
			return start;
		
		else if (index == end - start)
			return end;
		
		else
		{
			T s = start;
			
			for (size_t i = 0; i < end - 1; i++)
				if (i == index)
					return s;
				else
					s++;
			
			return T.max;
		}		
	}
	
	/**
	 * Returns the number of elements in the Range
	 * 
	 * Returns: the number of elements in the Range
	 */
	size_t length ()
	{
		return cast(size_t) end - start;
	}
}

/// An alias to the default Range type which is Range!(sise_t, size_t)
alias Range!() range;
