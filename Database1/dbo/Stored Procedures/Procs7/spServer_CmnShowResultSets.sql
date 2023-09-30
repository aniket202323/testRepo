CREATE PROCEDURE dbo.spServer_CmnShowResultSets
AS
Declare
 	 @RSTId int,
 	 @RSTDesc nVarChar(100), 	 
 	 @ColumnNum int,
 	 @UsedAsPropertyName 	 nVarChar(100)
 	  	 
 	 DECLARE RST_Cursor CURSOR READ_ONLY
 	  	 FOR Select RSTId,RSTDesc From ResultSetTypes
 	  	 Open RST_Cursor  
 	  	 RSTFetchLoop:
 	  	 Fetch Next From RST_Cursor Into @RSTId,@RSTDesc
 	  	 If (@@Fetch_Status = 0)
 	  	  	 Begin
 	  	  	  	 Print '------------------------------------------------------------------------------'
 	  	  	  	 Print @RSTDesc + ' (RSTId = ' + Convert(nVarChar(10),@RSTId) + ')'
 	  	  	  	 Print '------------------------------------------------------------------------------'
 	  	  	  	 DECLARE RSTCfg_Cursor CURSOR READ_ONLY
 	  	  	  	  	 FOR Select ColumnNum,UsedAsPropertyName From ResultSetConfig Where RSTId = @RSTId
 	  	  	  	  	 Open RSTCfg_Cursor  
 	  	  	  	  	 RSTCfgFetchLoop:
 	 
 	  	  	  	  	 Fetch Next From RSTCfg_Cursor Into @ColumnNum,@UsedAsPropertyName
 	  	  	  	  	 If (@@Fetch_Status = 0)
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 Print Convert(nVarChar(10),@ColumnNum) + ' - ' + @UsedAsPropertyName
 	  	  	  	  	  	  	 Goto RSTCfgFetchLoop
 	  	  	  	  	  	 End
 	  	  	  	 Close RSTCfg_Cursor
 	  	  	  	 Deallocate RSTCfg_Cursor
 	  	  	  	 Print ''
 	  	  	  	 Goto RSTFetchLoop
 	  	  	 End
 	 Close RST_Cursor
 	 Deallocate RST_Cursor
