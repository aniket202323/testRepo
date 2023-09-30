
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_QA_GetLocalProduct]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Ketki Pophali (Capgemini)
Date			:	2019-05-23
Version		:	1.3.0
Purpose		: 	FO-03488: App version entry in stored procedures using Appversions table
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-12-02
Version		:	1.2.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added script to register version.
-------------------------------------------------------------------------------------------------
Altered by 	Marc Charest, Solutions et Technologies Industrielles Inc.
On 		30-Aug-2004	
Version 	1.1.0
Purpose		If variable does not belong to an ATTR pu_group, SP returns list of 
		all local product names (@vcrLocalProducts).
-----------------------------------------------------------------------------------------------------------------------
Created by 	Marc Charest, Solutions et Technologies Industrielles Inc.
On 		13-Aug-2004	
Version 	1.0.0
Purpose		Depending on PUG description, SP returns a specific local product.
-------------------------------------------------------------------------------------------------
*/

@vcrLocalProducts		varchar(500),
@vcrPUGDesc 			varchar(50),
@vcrLocalProduct		varchar(50) output

AS
SET NOCOUNT ON

Declare
@vcrGlobalProducts	varchar(500),
@intProdID				integer,
@vcrProdDesc			varchar(50),
@intProdCount			integer,
@intCurrentProdID		integer

create table #LocalProducts
(
Prod_ID		integer,
Prod_Desc	varchar(50)
)

create table #GlobalProducts
(
Prod_ID		integer,
Prod_Desc	varchar(50)
)

--Parsing local products
insert into #LocalProducts
exec spCmn_ReportCollectionParsing					
		@vcrLocalProducts,	
		'',					
		'|',						
		'VarChar(500)'

--Getting global products
select 
	@vcrGlobalProducts = translated_text 
from 
	dbo.local_pg_translations WITH(NOLOCK)
where 
	global_text = 'PRODUCTATTR' and
	language_id in (select language_id from dbo.local_pg_languages WITH(NOLOCK) where language = 'english')


--Parsing global products
insert into #GlobalProducts
exec spCmn_ReportCollectionParsing					
		@vcrGlobalProducts,	
		'',					
		'|',						
		'VarChar(500)'

--Searching for global PUG like product
select @intProdCount = count(Prod_ID) from #GlobalProducts
set @intCurrentProdID = 1
while @intCurrentProdID <= @intProdCount begin
	select @vcrProdDesc = Prod_Desc from #GlobalProducts where Prod_ID = @intCurrentProdID
	if @vcrPUGDesc like '%' + @vcrProdDesc + '%' begin
		break 
	end
	set @intCurrentProdID = @intCurrentProdID + 1
end


--Translating & returning global PUG like product
select 
	@vcrLocalProduct = Prod_Desc
from 
	#LocalProducts
where 
	Prod_ID =  @intCurrentProdID


--be30-Aug-2004
if @vcrLocalProduct is null or @vcrLocalProduct = ''
	select @vcrLocalProduct = @vcrLocalProducts

drop table #LocalProducts
drop table #GlobalProducts

SET NOCOUNT OFF


