CREATE PROCEDURE dbo.spRS_DeleteReportTreeNode
@Node_Id int
 AS
Declare @Parent_Node_Id int
Declare @Temp_Node_Id int
Declare @Order_Num int
Declare @Msg varchar(200)
Declare @ReturnVal int
Select @ReturnVal = 0
Select @Order_Num = 1
--
-- Create 3 Temporary Tables
-- #Delete_Table
-- #Search_Table
-- #Temp_Table
--
CREATE TABLE #Delete_Table(
    Node_Id int,
    Order_Id int)
CREATE TABLE #Search_Table(
    Node_Id int)
CREATE TABLE #Temp_Table(
    Node_id int)
-- ***********************
-- Set up the search table
-- ***********************
INSERT INTO #Search_Table(
  Node_Id)
VALUES(
  @Node_Id)
-- ***********************
-- Setup Cursor
-- ***********************
StartCursor:
Declare Search_Cursor CURSOR
  FOR SELECT Node_Id from #Search_Table
  FOR READ ONLY
  OPEN Search_Cursor
-- **********************
-- Sub Parse The Search Table
-- **********************
ParseSearchTable:
  FETCH NEXT FROM Search_Cursor
    INTO @Temp_Node_Id
  IF @@Fetch_Status = 0
    Begin
      Insert into #Delete_Table
         (Node_Id, Order_Id)
     Values
         (@Temp_Node_Id, @Order_Num)
         Select @Order_Num = @Order_Num + 1
      Insert into #Temp_Table
 	 (Node_Id)
      Select Node_Id
        From Report_Tree_Nodes
        Where Parent_Node_Id = @Temp_Node_Id
        AND Node_Id <> @Temp_Node_Id
-- 	 Select @Msg = "Working on " + Convert(Varchar(10), @Temp_Node_Id)
--      Print @Msg
        Goto ParseSearchTable
    End
  Else
    Begin
--      Select * from #Temp_Table
      Delete From #Search_Table
      Insert Into #Search_Table(
        Node_Id)
      Select Node_Id 
        From #Temp_Table
      Delete From #Temp_Table
      IF (Select Count(*) 
           From #Search_Table) > 0
          Begin
            Close Search_Cursor
            Deallocate Search_Cursor
--   	     Select @Msg = "Done with cursor"
--           Print @Msg
            GOTO StartCursor
          End
    End
Select * From #Delete_Table
  Order By Order_Id Desc
Select Node_Id, Parent_Node_Id
 from Report_Tree_Nodes
  Where Node_Id In (Select Node_Id from #Delete_Table)
Close Search_Cursor
Deallocate Search_Cursor
Declare Delete_Cursor CURSOR
  FOR SELECT Node_Id from #Delete_Table   
  Order By Order_Id Desc
  FOR READ ONLY
  OPEN Delete_Cursor
SubDelete:
  FETCH NEXT FROM Delete_Cursor
    INTO @Temp_Node_Id
  If @@Fetch_Status = 0
   Begin
     Delete From Report_Tree_Nodes
      Where Node_Id = @Temp_Node_Id
      GOTO SubDelete
   End
If @@Error <> 0 
  Select @ReturnVal = 1
Close Delete_Cursor
Deallocate Delete_Cursor
Close Search_Cursor
Deallocate Search_Cursor
Drop Table #Delete_Table
Drop Table #Search_Table
Drop Table #Temp_Table
Return @ReturnVal
