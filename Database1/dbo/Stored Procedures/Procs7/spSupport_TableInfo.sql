CREATE PROCEDURE dbo.spSupport_TableInfo 
@TableName varchar(100)
AS
Set NoCount On
Declare 
  @TableId int,
  @Msg varchar(100),
  @NumFields int,
  @TotalSize int
Select @TableName = Upper(@TableName)
Select @TableId = Id 
  From sys.sysobjects 
  Where Name = @TableName
Select @NumFields = Count(a.Name)
  From sys.syscolumns a
  Join sys.systypes b on b.Usertype = a.Usertype
  Where a.Id = @TableId
Select @TotalSize = Sum(a.Length)
  From sys.syscolumns a
  Join sys.systypes b on b.Usertype = a.Usertype
  Where a.Id = @TableId
Select @Msg = 'Table - ' + @TableName + ' - ' + Convert(Varchar(30),@NumFields) + ' - ' + Convert(Varchar(30),@TotalSize)
Print @Msg
Print ''
Select I = 
          Case a.Status
            When 128 Then
              'X'
            Else
              ''
          End,
       N = 
         Case a.Status
           When 8 Then
             'X'
           Else
             ''
         End,
       D = 
         Case a.cDefault
           When 0 Then
             ''
           Else
             'X'
         End,
       Name = a.Name,
       Type = Substring(b.Name,1,29),
       Len = a.Length
  From sys.syscolumns a
  Join sys.systypes b on b.Usertype = a.Usertype
  Where a.Id = @TableId
  Order by a.Colid
Set NoCount Off
