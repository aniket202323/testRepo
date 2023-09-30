CREATE PROCEDURE dbo.spEM_GetProductByChar
  @Prop_Id int,
  @CharIds nvarchar(1000)
  AS
  --
  Declare 	 @PrevCharId Int,
 	  	 @PUId          Int,
 	  	 @Char_Id 	 Int
  --
  -- Find the master unit
  --
--  SELECT @Master_PU_Id = Master_Unit FROM Prod_Units WHERE PU_Id = @PU_Id
 -- IF @Master_PU_Id IS NULL SELECT @Master_PU_Id = PU_ID FROM Prod_Units WHERE PU_Id = @PU_Id
  --
 Create Table #MasterPUs(PU_Id Int)
 Create Table #PUs(PU_Id Int)
 Create Table  #Prods(Prod_Id Int,Char_Id Int )
 Create Table #CharIds(Char_Id integer)
 Create Table #CharId2(Char_Id integer)
 Create Table #CharId3(Char_Id integer)
 Create Table  #Chars(Char_Id Int)
While (LEN( LTRIM(RTRIM(@CharIds))) > 1) 
  Begin
       Insert into #Chars (Char_Id) Values (Convert(Int,SubString(@CharIds,1,CharIndex(Char(1),@CharIds)-1)))
       Select @CharIds = SubString(@CharIds,CharIndex(Char(1),@CharIds),LEN(@CharIds))
       Select @CharIds = Right(@CharIds,LEN(@CharIds)-1)
  End
Execute( 'Declare c Cursor Global For Select Char_Id From #Chars For Read Only')
open c
cLoop:
Fetch next from c into @Char_Id
If @@Fetch_Status = 0 
 Begin  
   Declare PU_Cursor  Cursor 
   For Select Distinct v.PU_Id From Variables v
 	 Join Specifications sp on sp.spec_Id = v.spec_Id  and sp.prop_Id = @Prop_Id
   Open PU_Cursor
   NextPu:
    Fetch Next From PU_Cursor InTo @PUId
    If @@Fetch_Status  = 0 
      Begin
 	 Insert into #PUs select Coalesce(Master_Unit,@PUId) From Prod_Units where PU_Id = @PUId
 	 Goto NextPu
      End
   Close PU_Cursor
   Deallocate PU_Cursor
   Insert Into #MasterPUs Select Distinct PU_Id from #PUs
   Delete from #PUs
   Insert Into #CharIds(Char_Id) Values(@Char_Id)
    Execute( 'Declare Char_Cursor Cursor Global ' +
   'For Select Char_Id From #CharIds ' +
   'For Read Only')
   Open  Char_Cursor
   FetchNextChar:
   Fetch Next From Char_Cursor into @Char_Id
    IF @@Fetch_Status = 0
 	 Begin
  	      Insert into #Prods
 	  	 SELECT   Prod_Id,Char_Id
 	  	   From Pu_Characteristics
 	  	  WHERE PU_Id In (select PU_Id from #MasterPUs)  And Char_Id = @Char_Id and Prop_Id = @Prop_Id
 	     Goto FetchNextChar
 	 End
 	 Close Char_Cursor
 	 Deallocate Char_Cursor
  goto cloop
  Delete from  #CHARIDS
  Delete From #MasterPUs
End
close c
Deallocate c
Drop Table #MasterPUs
DROP TABLE #CHARIDS
Drop Table #PUs
  -- Get the valid products for this production unit.
  --
Select Distinct Prod_Id,Char_Id From #Prods
Drop Table #Prods
