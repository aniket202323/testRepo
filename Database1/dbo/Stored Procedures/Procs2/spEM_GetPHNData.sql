CREATE PROCEDURE dbo.spEM_GetPHNData 
  @PHN_Id       int
  AS
  --
  Declare @HistType Int
  Select @HistType = Hist_Type_Id From Historians    WHERE Hist_Id = @PHN_Id
  Select Is_Active ,Is_Remote,Alias = Coalesce(Alias,Hist_ServerName)
 	 From Historians
    WHERE Hist_Id = @PHN_Id
 Create Table #HistData(Hist_Option_Id Int ,Hist_Option_Desc nvarchar(25),Field_Type_Id Int,
 	  	  	  	  	  	 Value nvarchar(1000),sp_Lookup Int,Field_Type_Desc nVarChar(100),Store_Id Int,Value_Text nvarchar(1000) Null)
Insert Into   #HistData(Hist_Option_Id,Hist_Option_Desc,Field_Type_Id,
 	  	  	  	  	  	 Value ,sp_Lookup ,Field_Type_Desc,Store_Id)
 Select ht.Hist_Option_Id,h.Hist_Option_Desc,Field_Type_Id,s.Value,ft.sp_Lookup,ft.Field_Type_Desc,ft.Store_Id
 From Historian_Type_Options ht
 left Join Historian_Options h on h.Hist_Option_Id = ht.Hist_Option_Id
 Left Join Historian_Option_Data s on s.Hist_Option_Id = ht.Hist_Option_Id and s.Hist_Id = @PHN_Id 
 Left Join Ed_FieldTypes ft on ft.Ed_Field_Type_Id = h.Field_Type_Id 
 where ht.Hist_Type_Id = @HistType  and ht.Hist_Option_Id != 5 /*  Port data not available in admin  - requires manual insert too many customers do it wrong*/
 order by h.Hist_Option_Desc
Declare @Ft Int,@Value nvarchar(1000),@NewValue nvarchar(1000)
Declare HistCursor Cursor for 
 	 Select Field_Type_Id,Value From #HistData
For Update
Open HistCursor
HistCursorLoop:
 Fetch Next from HistCursor into @FT,@Value
IF @@Fetch_Status = 0
  Begin
 	 if (@FT = 9) or (@FT = 38) or(@FT = 41) or(@FT = 42) or(@FT = 43)
 	   Begin
 	  	 Select @NewValue = null
 	  	 Select @NewValue = Field_Desc
 	  	  	 From ED_FieldType_ValidValues 
 	  	  	 Where  ED_Field_Type_Id = @FT and  convert(nvarchar(25),Field_Id) = @Value
 	  	 Update #HistData Set Value_Text = @NewValue Where current of HistCursor
 	   End
 	 Else
 	  Begin
 	  	 Update #HistData Set Value_Text = @Value Where current of HistCursor
 	  End
 	 goto HistCursorLoop
  End
Close HistCursor
Deallocate HistCursor
If  @HistType = 7 --Proficy
 	 Delete From #HistData
select * from #HistData
Drop Table #HistData
