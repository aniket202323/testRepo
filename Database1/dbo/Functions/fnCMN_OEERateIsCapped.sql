create function dbo.[fnCMN_OEERateIsCapped] ()
 	 Returns Bit
AS
BEGIN
 	 Declare @Answer nvarchar(5), @RtnCode bit
 	 select @Answer = Value from site_parameters where parm_id=317
 	 ---------------------------------------------------------
 	 -- Parameter 317 is OEE Max Limit Override WHERE
 	 -- False = Cap the OEE (do not let if exceed 100%)
 	 -- True = Allow OEE to Exceed 100%
 	 ---------------------------------------------------------
 	 If @Answer Is Null
 	  	 Select @RtnCode = 1 -- Default= YES Cap the OEE
 	 Else If UPPER(@Answer) = 'FALSE'
 	  	 Select @RtnCode = 1 -- Do Not Let OEE Exceed 100%
 	 Else
 	  	 Select @RtnCode = 0 -- Override - Allow OEE To Exceed 100%
 	 
 	 /*
 	 If @Answer Is Null
 	  	 Select @RtnCode = 0
 	 Else If UPPER(@Answer) = 'TRUE'
 	  	 Select @RtnCode = 0
 	 Else
 	  	 Select @RtnCode = 1
 	 */
 	 Return @RtnCode
END
