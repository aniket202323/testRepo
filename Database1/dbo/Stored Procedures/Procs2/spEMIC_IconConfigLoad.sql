Create Procedure dbo.spEMIC_IconConfigLoad 
AS
  Begin
    Create Table #IC (Icon_Id Int,Icon_Desc nVarChar(100),IsDeleteable Int,InDatabase Int)
    Insert Into #IC
      Select Icon_Id,Icon_Desc,[IsDeleteable] = Coalesce(DoNotDelete,0),
 	 [InDatabase] = case when Icon is null then 0
 	  	  	 Else 1
 	  	  	 End
      from Icons order by icon_desc
    Update #IC set IsDeleteable = 1 Where Icon_Id in (select Distinct Icon_Id From event_subtypes)
    Update #IC set IsDeleteable = 1 Where Icon_Id in (select Distinct Icon_Id From Production_Status)
    Select Icon_Id,Icon_Desc,IsDeleteable,InDatabase From #IC
  End
