CREATE PROCEDURE dbo.spEM_IEGetColumnData 
  @DataType    nVarChar(100)
  AS
Declare @Field_Name 	  	  	 nvarchar(50),
 	  	 @Comment 	  	  	 nVarChar(100),
 	  	 @Comment_Field_SQL  nvarchar(500),
 	  	 @OutComment  	  	 nvarchar(1000),
 	  	 @CommentPart  	  	 nVarChar(100),
 	  	 @Trans 	  	  	 bit,
 	  	 @FirstField 	  	 int,
 	  	 @TransType 	  	 Int,
 	  	 @IsText 	  	  	 TinyInt,
 	  	 @ExcelDateFormat  	 nVarChar(25)
Select @TransType = Is_Type_Needed From import_Export_Types where IE_Type_Desc = @DataType
Create Table #ColumnNames(Column_Name nVarChar(100),Comment nvarchar(1000),Trans Bit,FirstField Int,Is_Text TinyInt,ExcelDateFormat nVarChar(25), SerialNo int Identity(1,1))
Insert into #ColumnNames(Column_Name,Comment,Trans,Is_Text,ExcelDateFormat) Values('Return Messages',Null,0,0,Null)
If @TransType = 1
 	 Insert into #ColumnNames(Column_Name,Comment,Is_Text,Trans,ExcelDateFormat) Values('Selected','(X) to Select' + char(10) + '(D) to Delete',0,0,Null)
ELSE If @TransType = 2
 	 Insert into #ColumnNames(Column_Name,Comment,Is_Text,Trans,ExcelDateFormat) Values('Selected','(I) Insert' + char(10) + '(U) Update' + char(10) + '(D) Delete',0,0,Null)
ELSE
 	 Insert into #ColumnNames(Column_Name,Comment,Trans,Is_Text,ExcelDateFormat) Values('Selected','(X) to Select',0,0,Null)
Declare ImportExport Cursor
 	 For Select Field_Name,Comment,Comment_Field_SQL,Is_Trans_Needed,First_Required_Data_Column,Is_Text,ExcelDateFormat
 	 From Import_Export_Fields ief
 	 Join Import_Export_Types iet on iet.IE_Type_Id = ief.IE_Type_Id
 	 Where  iet.IE_Type_Desc = @DataType
 	 Order By Field_Order
Open ImportExport
BTLoop:
 	 Fetch Next From ImportExport Into @Field_Name,@Comment,@Comment_Field_SQL,@Trans,@FirstField,@IsText,@ExcelDateFormat
 	 If @@Fetch_Status = 0
 	   Begin
 	  	 If @Comment_Field_SQL is Null Or @Comment_Field_SQL = ''
 	  	  	 Insert Into #ColumnNames(Column_Name,Comment,trans,FirstField,Is_Text,ExcelDateFormat) Values(@Field_Name,@Comment,@Trans,@FirstField,@IsText,@ExcelDateFormat)
 	  	 Else
 	  	   Begin
 	  	  	 Select @OutComment  = ''
 	  	  	 If @Comment is not null And @Comment <> ''
 	  	  	  	 Select @OutComment = @Comment
 	  	  	  	 DECLARE @CursorOpen nvarchar(1000)
 	  	  	  	 SET @CursorOpen = N'Declare IEGetColumnData_Cursor cursor Global For ' + @Comment_Field_SQL
 	  	  	  	 EXEC  sp_executesql @CursorOpen
     	  	 Open IEGetColumnData_Cursor
  	  	   CommentLoop:
 	  	  	 Fetch Next From IEGetColumnData_Cursor Into @CommentPart 
 	  	     If @@Fetch_Status = 0
 	  	  	   Begin
 	  	  	  	 If @OutComment <> '' 
 	  	  	  	  	 Select @OutComment  = @OutComment + char(10) + @CommentPart 
 	  	  	  	 Else
 	  	  	  	  	 Select @OutComment  =  @CommentPart
 	      	  	 Goto CommentLoop
 	  	  	   End
 	  	  	 Close IEGetColumnData_Cursor
 	  	  	 Deallocate IEGetColumnData_Cursor
 	  	  	 Insert into #ColumnNames(Column_Name,Comment,Trans,FirstField,Is_Text,ExcelDateFormat) Values(@Field_Name,@OutComment,@Trans,@FirstField,@IsText,@ExcelDateFormat)
 	  	   End
 	  	 Goto BTLoop
 	   End
Close ImportExport
deallocate ImportExport
Select Column_Name,Comment,Trans,FirstField,Is_Text,ExcelDateFormat,SerialNo from #ColumnNames 
Order by SerialNo
drop table #ColumnNames
