CREATE PROCEDURE dbo.spEM_cmnCleanUpPEP
  @PU_Id int,
  @ItemType 	 nVarChar(2),
 	 @IsUnit int
 AS
Declare 	 @SearchString nvarchar(1000),
 	  	    	 @Id Int,
 	  	    	 @OverView_Positions VarChar(7000),
 	  	    	 @Start Int,
 	  	  	 @End Int,
 	  	  	 @DeleteString nvarchar(1000)
Select @DeleteString =   char(1) + @ItemType + char(1) +Convert(nVarChar(10),@PU_Id) + Char(1)
Select @SearchString =  '%' + @DeleteString + '%'
If @IsUnit = 0
 	 Begin
 	  	 Declare Line_Cursor Cursor For
 	  	 select PL_Id,OverView_Positions from prod_Lines where OverView_Positions like @SearchString
 	  	 Open Line_Cursor
 	  	 Next_Line_Cursor:
 	  	 Fetch Next from Line_Cursor into @Id,@OverView_Positions
 	  	 If @@Fetch_Status = 0
 	  	   Begin
 	  	  	  	 Select @Start = CharIndex(@DeleteString,@OverView_Positions,1)
 	  	  	  	 Select @End = CharIndex(char(1),@OverView_Positions,@Start + len(@DeleteString) + 1) --Top
 	  	  	  	 Select @End = CharIndex(char(1),@OverView_Positions,@End + 1) --Left
 	  	  	  	 Select @DeleteString = substring(@OverView_Positions,@Start,@End - @Start)
 	  	  	  	 Select @OverView_Positions
 	  	  	  	 Select @DeleteString
 	  	  	  	 Select @OverView_Positions = replace(@OverView_Positions,@DeleteString,'')
 	  	  	  	 Update prod_Lines set OverView_Positions = @OverView_Positions Where PL_Id = @Id
 	  	  	  	 GoTo Next_Line_Cursor
 	  	   End
 	  	 close Line_Cursor
 	  	 deallocate Line_Cursor
 	 End
Else
  Begin
 	  	 Declare Sheet_Cursor Cursor For
 	  	 select Sheet_Id,Value from Sheet_Display_Options where  Display_Option_Id = 159 and Value like @SearchString
 	  	 Open Sheet_Cursor
 	  	 Next_Sheet_Cursor:
 	  	 Fetch Next from Sheet_Cursor into @Id,@OverView_Positions
 	  	 If @@Fetch_Status = 0
 	  	   Begin
 	  	  	  	 Select @Start = CharIndex(@DeleteString,@OverView_Positions,1)
 	  	  	  	 Select @End = CharIndex(char(1),@OverView_Positions,@Start + len(@DeleteString) + 1) --Top
 	  	  	  	 Select @End = CharIndex(char(1),@OverView_Positions,@End + 1) --Left
 	  	  	  	 Select @DeleteString = substring(@OverView_Positions,@Start,@End - @Start)
 	  	  	  	 Select @OverView_Positions = replace(@OverView_Positions,@DeleteString,'')
 	  	  	  	 Update Sheet_Display_Options set Value = @OverView_Positions Where Sheet_Id = @Id and Display_Option_Id = 159
 	  	  	  	 GoTo Next_Sheet_Cursor
 	  	   End
 	  	 close Sheet_Cursor
 	  	 deallocate Sheet_Cursor
  End
