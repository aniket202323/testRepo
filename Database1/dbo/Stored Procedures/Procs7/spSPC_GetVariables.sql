Create Procedure dbo.spSPC_GetVariables
@VariableList nvarchar(1000)
AS
Select @VariableList = @VariableList + '$'
Create Table #IdList (
  ItemId int,
  ItemOrder int
)
declare @CurIds nvarchar(1000)
declare @i integer
declare @IdCount integer
declare @tchar char
declare @tvchar nvarchar(10)
declare @tID integer
select @tvchar = ''
Select @IdCount = 0
Select @i = 1 	  	     
Select @CurIds = @VariableList
Select @tchar = SUBSTRING (@CurIds, @i, 1)
While (@tchar <> '$') And (@i < 999)
  Begin
     If @tchar <> ',' And @tchar <> '_'
       Select @tvchar = @tvchar + @tchar
     Else
       Begin
         Select @tvchar = LTRIM(RTRIM(@tvchar))
         If @tvchar <> '' 
           Begin
             Select @tID = CONVERT(integer, @tvchar)
             Select @IdCount = @IdCount + 1
             Insert into #IdList (ItemId, ItemOrder) values (@tID, @IdCount)
           End
           If @tchar = ','
             Begin
 	        Select @tvchar = ''
 	      End
           Else -- Go To Next Set Of Ids (@tchar = '_')
             Begin
 	        Select @tvchar = ''
 	        Select @CurIds = @VariableList
 	        Select @i = 0
 	      End
       End
     Select @i = @i + 1
     Select @tchar = SUBSTRING(@CurIds, @i, 1)
  End
 	  	 
Select @tvchar = LTRIM(RTRIM(@tvchar))
If @tvchar <> '' 
  Begin
    Select @tID = CONVERT(integer, @tvchar)
    Select @IdCount = @IdCount + 1
    Insert into #IdList (ItemId, ItemOrder) values (@tID, @IdCount)
  End
Select Id = v.Var_Id,
       Description = v.Var_Desc, 
       VariableType = Case 
                        When  v.Data_Type_Id > 50 Then 'Attribute'
                        When  v.Data_Type_Id  = 3 Then 'Attribute'
                        When  v.Data_Type_Id  = 5 Then 'Attribute'
                        Else 'Variable'
                      End, 
       EventType = et.ET_Desc, Unit = p.PU_Desc, DataSource = ds.DS_Desc,
       Var_Precision = Coalesce(v.Var_Precision,0)
  From Variables v
  Join Event_Types et on et.ET_Id = v.Event_Type
  Join Prod_Units p on p.PU_Id = v.PU_Id
  Join Data_Source ds on ds.DS_Id = v.DS_Id
  Join #IdList i on i.ItemId = v.Var_Id
  Order By i.ItemOrder ASC
