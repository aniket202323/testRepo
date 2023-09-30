CREATE PROCEDURE dbo.spALM_GetDispOption 
@Sheet_ID int,
@Display_Option_Id int
as
  Declare @Sheet_Type int
  Select @Sheet_Type = Sheet_Type from Sheets Where Sheet_Id = @Sheet_ID
 	 Create Table #Display_Options (
 	   Display_Option_Id int, 
 	   Value nvarchar(100), 
    Binary_Id int
 	   )
 	 
 	 Insert into #Display_Options (Display_Option_Id,Value,Binary_Id)
  Select Display_Option_Id, Value, binary_id from Sheet_Display_Options where sheet_Id = @Sheet_Id and Display_Option_Id = @Display_Option_ID
 	 
  If (Select Count(*) from #Display_Options) = 0
    Begin
     	 Insert into #Display_Options (Display_Option_Id,Value,Binary_Id)
       	 Select stdo.Display_Option_Id, stdo.Display_Option_Default, NULL
   	       From Sheet_Type_Display_Options stdo
          Where stdo.Display_Option_Id = @Display_Option_Id and stdo.Sheet_Type_Id = @Sheet_Type
    End
  Select value, binary_id from #Display_Options
 	 Drop Table #Display_Options
