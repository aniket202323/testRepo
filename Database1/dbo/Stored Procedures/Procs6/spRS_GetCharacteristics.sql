CREATE PROCEDURE dbo.spRS_GetCharacteristics 
@Property_Id int,
@ExcludeStr varchar(8000) = Null,
@Flag int = 0
AS
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
Create Table #T (OrderId int, MyId Int)
Select @I = 1
Select @INstr = @ExcludeStr + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
    insert into #T (OrderId, MyId) Values (@I,@Id)
    Select @I = @I + 1
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
If @Flag = 0
  Begin
 	 If @Property_Id Is Null
 	   Begin
 	     If @ExcludeStr Is Null
 	       Begin
 	  	  	 Select CharacteristicId = Char_Id, CharacteristicDesc = Char_Desc
 	  	  	   From Characteristics
 	  	  	   Order By Char_Desc 
 	  	  End
 	     Else
 	       Begin
 	  	  	 Select CharacteristicId = Char_Id, CharacteristicDesc = Char_Desc
 	  	  	   From Characteristics
 	  	  	   Where Char_Id not in (Select MyId From #t)
 	  	  	   Order By Char_Desc  	       
 	       End
 	   End
 	   
 	 Else
 	   Begin
 	     If @ExcludeStr Is Null
 	       Begin
 	  	  	 Select CharacteristicId = Char_Id, CharacteristicDesc = Char_Desc
 	  	  	   From Characteristics
 	  	  	   Where Prop_Id = @Property_Id
 	  	  	   Order By Char_Desc  
 	  	  End
 	     Else
 	       Begin
 	  	  	 Select CharacteristicId = Char_Id, CharacteristicDesc = Char_Desc
 	  	  	   From Characteristics
 	  	  	   Where Prop_Id = @Property_Id
 	  	  	   and Char_Id not in (Select MyId From #t)
 	  	  	   Order By Char_Desc   	       
 	       End
 	   End
  End
Else
  Begin
 	 --Include Characteristics
 	 Select MyId, C.Char_Desc From #t Join Characteristics C on C.Char_Id = #t.MyId 	 
  End
