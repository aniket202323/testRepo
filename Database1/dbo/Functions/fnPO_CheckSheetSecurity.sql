/*

*/
CREATE FUNCTION [dbo].[fnPO_CheckSheetSecurity](
    @Path_Id 	  	  	 int,
    @Option1 	  	 Int,
    @DefaultLevel 	 Int,
    @UsersSecurity 	 Int,
    @Sheet_Id Int)
    RETURNS  Int
AS
BEGIN
    DECLARE @CurrentLevel Int
    DECLARE @OKay Int
    SET @CurrentLevel = Null
    IF @Option1 is Not Null
        BEGIN
            Select @CurrentLevel = a.Value
            from Sheet_Display_options a
                     Join display_Options b on b.Display_Option_Id = a.Display_Option_Id
                     Join Sheet_Type_Display_Options c on c.Display_Option_Id = b.Display_Option_Id
                     Join Sheets s on s.Sheet_Id = a.Sheet_Id
                     Left Join Sheet_Unit su on su.sheet_Id = s.sheet_Id
                     Left Join Sheet_Paths sp on sp.sheet_Id = s.sheet_Id
            WHERE   a.Display_Option_Id = @Option1 and Sheet_Type_Id = 17  and sp.Path_Id = @Path_Id AND s.Sheet_Id = @Sheet_Id
        END
    SELECT @CurrentLevel = Coalesce(@CurrentLevel,@DefaultLevel) -- Default
    IF @Option1 = 404 -- for option 404, it is allow unbounded status change, and there are not access levels for it, it's just 0/1
        SET @OKay = @CurrentLevel
    ELSE IF @UsersSecurity >= @CurrentLevel
        SET @OKay = 1
    ELSE
        SET @OKay = 0
    Return @OKay
END

