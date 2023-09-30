Create Procedure dbo.spEMCO_DeleteOrder
@ID int,
@User_Id int
AS
  DECLARE @Insert_Id int 
 INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMCO_DeleteOrder',
                convert(nVarChar(10), @ID) +  "," + Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
create table #LineItems (ItemIDs int)
    insert into #LineItems
        select Order_Line_Id  from Customer_Order_Line_Items where order_Id = @ID
create table #Specs (theID int)
    insert into #Specs 
        select Order_Spec_Id from Customer_Order_Line_Specs where Order_Line_Id in (select ItemIDs from #LineItems)
create table #Com_Ids (Line_Id int, Cmnt_Id int)
    insert into #Com_Ids
      SELECT Order_Line_Id, Comment_Id
      FROM Customer_Order_Line_Items
     WHERE Order_Id = @ID AND Comment_Id IS NOT NULL
create table #Order_Comment (Comment_Id int)
    insert into #Order_Comment
      SELECT Comment_Id
      FROM Customer_Orders
     WHERE Order_Id = @ID AND Comment_Id is not null
Declare @Comment_Id int
Select @Comment_Id = Comment_Id from Customer_Orders where Order_Id = @Id
exec spCSS_InsertDeleteComment @Id, 28, 1, 1, null,@comment_Id
Declare
  @@Order_Line_Id int,
  @@Comment_Id int
Declare MyCursor INSENSITIVE CURSOR
  For (Select * from #Com_Ids)
  For Read Only
  Open MyCursor  
MyLoop1:
  Fetch Next From MyCursor Into @@Order_Line_Id, @@Comment_Id
  If (@@Fetch_Status = 0)
    Begin
 	 exec spCSS_InsertDeleteComment @@Order_Line_Id, 29, 1, 1, null, @@Comment_Id
      Goto MyLoop1
    End
Close MyCursor
Deallocate MyCursor
update Comments
set ShouldDelete = 1
where Comment_Id in (select Cmnt_Id from #Com_Ids)
update Comments
set ShouldDelete = 1
where Comment_Id in (select Comment_Id from #Order_Comment)
delete from Customer_Order_Line_Specs where Order_Spec_Id in (Select theID from #Specs)
delete from Customer_Order_Line_Items where Order_Id = @ID
delete from Customer_Orders where order_Id = @id
Drop table #LineItems
Drop table #Specs
Drop table #Com_Ids
Drop table #Order_Comment
UPDATE Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
