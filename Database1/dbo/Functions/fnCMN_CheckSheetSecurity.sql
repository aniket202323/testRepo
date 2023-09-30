CREATE FUNCTION dbo.fnCMN_CheckSheetSecurity(@UnitId int, 
 	  	  	  	  	 @DtOption 	 Int, 
 	  	  	  	  	 @DtpOption 	 Int,
 	  	  	  	  	 @DefaultLevel 	 Int,
 	  	  	  	  	 @UsersSecurity 	 Int) 
  	  RETURNS  Int
AS 
BEGIN
 	 DECLARE @CurrentLevel Int
 	 DECLARE @OKay Int
 	 SET @CurrentLevel = Null
 	  Select @UnitId = CASE 
 	  WHEN Master_Unit IS NULL THEN pu_Id else MAster_Unit
 	  END from Prod_Units where Pu_Id = @UnitId
  	  IF @DtOption is Not Null  Or @DtpOption Is Not Null
  	  BEGIN
 	  ;WITH ActiveSheets As (
 	  Select distinct s.Sheet_Type from Sheet_Unit su right outer join Sheets s on s.Sheet_Id = su.Sheet_Id and s.Is_Active = 1 where (su.PU_Id=@UnitId or s.master_unit =@UnitId)
 	  )
 	  ,DefaultSecurityValues As 
 	  (
 	  	 Select 
 	  	  	 Display_Option_Id,Sheet_Type_Id,Display_option_default 
 	  	 from 
 	  	  	 Sheet_Type_Display_Options A
 	  	 where 
 	  	  	 (Display_Option_Id = @DtOption and sheet_Type_Id in (5) and exists (select 1 from ActiveSheets Where Sheet_Type = 5))
 	  	  	 or
 	  	  	 (Display_Option_Id = @DtOption and sheet_Type_Id in (15) and exists (select 1 from ActiveSheets Where Sheet_Type = 15))
 	  	  	 OR
 	  	  	 (Display_Option_Id = @DtpOption and sheet_Type_Id in (28) and exists (select 1 from ActiveSheets Where Sheet_Type = 28))
 	  	  	 OR
 	  	  	 (Display_Option_Id = @DtpOption and sheet_Type_Id in (4,26,29) and exists (select 1 from ActiveSheets Where Sheet_Type in (4,26,29)))
 	 )
 	  ,ActualSecurityValues AS 
 	  (
 	  	  	 Select 
 	  	  	  	  	 s.Sheet_Type, b.Display_option_Id,
 	  	  	  	  	 a.value,row_number() over (Order By 
 	  	  	  	  	 CASE 
 	  	  	  	  	 WHEN Sheet_Type_id = 28 THEN 1 
 	  	  	  	  	 WHEN Sheet_Type_id = 5 THEN 2 
 	  	  	  	  	 WHEN Sheet_Type_id = 15 THEN 3 
 	  	  	  	  	 WHEN Sheet_Type_id= 29 THEN 1 
 	  	  	  	  	 WHEN Sheet_Type_id= 4 THEN 2 
 	  	  	  	  	 WHEN Sheet_Type_id= 26 THEN 3 
 	  	  	  	  	 END 	 
 	  	  
 	  	  	  	  	 ) rownum
 	  	  	 from 
 	  	  	  	 Sheet_Display_options a
 	  	  	  	 Join display_Options b on b.Display_Option_Id = a.Display_Option_Id
 	  	  	  	 Join Sheet_Type_Display_Options c on c.Display_Option_Id = b.Display_Option_Id 
 	  	  	  	 Join Sheets s on s.Sheet_Id = a.Sheet_Id and s.Is_Active = 1
 	  	  	  	 Left Join Sheet_Unit su on su.sheet_Id = s.sheet_Id
  	    	    	  WHERE  
 	  	  	  	 (a.Display_Option_Id = @DtOption and ((Sheet_Type_Id = 5  and s.Master_Unit = @UnitId)
  	    	    	    	   or (Sheet_Type_Id = 15 and a.Display_Option_Id = @DtOption  and su.PU_Id = @UnitId))) 
  	    	    	    	   or (a.Display_Option_Id = @DtpOption and Sheet_Type_Id = 28  and su.PU_Id = @UnitId) 
 	  	  	  	   OR  (a.Display_Option_Id = @DtpOption and Sheet_Type_Id in (4,26)  and s.Master_Unit = @UnitId) 
 	  	  	  	   OR  (a.Display_Option_Id = @DtpOption and Sheet_Type_Id in (29)  and su.PU_Id = @UnitId) 
 	  	 )
 	  	 ,Temp as (Select 
 	  	  	 S.Display_Option_Id,S.Sheet_Type_Id,ISNULL(S1.Value,S.Display_option_Default) Value,row_number() over (Order By 
 	  	  	  	  	 CASE 
 	  	  	  	  	 WHEN S.Sheet_Type_id = 28 THEN 1 
 	  	  	  	  	 WHEN S.Sheet_Type_id = 5 THEN 2 
 	  	  	  	  	 WHEN S.Sheet_Type_id = 15 THEN 3 
 	  	  	  	  	 WHEN Sheet_Type_id= 29 THEN 1 
 	  	  	  	  	 WHEN Sheet_Type_id= 4 THEN 2 
 	  	  	  	  	 WHEN Sheet_Type_id= 26 THEN 3 
 	  	  	  	  	 END 	 ) rownum
 	  	 from 
 	  	  	 DefaultSecurityValues S 
 	  	  	 LEFT OUTER JOIN ActualSecurityValues S1 oN S.Display_Option_Id = S1.Display_option_Id and S.Sheet_Type_Id = S1.Sheet_Type  
 	  	  	 )
 	  	  	  	   select @CurrentLevel = MIN(Value) from Temp Where rownum = 1
  	  END
  	  SELECT @CurrentLevel = Coalesce(@CurrentLevel,@DefaultLevel) -- Default
  	  IF @UsersSecurity >= @CurrentLevel
  	    	  SET @OKay = 1
  	  ELSE
  	    	  SET @OKay = 0
  	  Return @OKay
END
