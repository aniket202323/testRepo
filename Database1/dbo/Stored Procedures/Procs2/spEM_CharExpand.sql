Create Procedure dbo.spEM_CharExpand 
 	 @Char_Id 	 int
 AS
Declare 	  	 @Char1 	  	 int,
 	  	 @Defined 	 Int,
 	  	 @PrevChar 	 Int
Create Table #ExpChar1(Char_Id int)
Create Table #ExpChar2(Char_Id int)
Create Table #ExpChar3(Char_Id int)
Insert Into #ExpChar1 (Char_Id) Values  (@Char_Id)
Loop:
Execute ('Declare C_Cursor Cursor Global For ' +
 	   'Select Char_Id From #ExpChar1 ' +
 	   'For Read only')
Open C_Cursor
NextChar:
Fetch Next From C_Cursor Into @Char1
  If @@Fetch_Status = 0
     Begin
 	 Insert into #ExpChar2
 	    Select Char_Id From Characteristics Where Derived_From_Parent = @Char1
 	 GoTo NextChar
     End
Close C_Cursor
Deallocate C_Cursor
If (Select Count(*) from #ExpChar2) > 0
    Begin
       Insert Into #ExpChar3 Select Char_Id From #ExpChar2
       Delete From #ExpChar1
       Insert Into #ExpChar1 Select Char_Id From #ExpChar2
       Delete From #ExpChar2
       GoTo Loop
    End
select Distinct Char_Id From #ExpChar3
