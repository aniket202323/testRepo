CREATE TABLE [dbo].[Local_PG_MESWebService_Instances] (
    [Instance_Id]   INT           IDENTITY (1, 1) NOT NULL,
    [Instance_Desc] VARCHAR (255) NOT NULL,
    [Instance_URL]  VARCHAR (255) NULL,
    CONSTRAINT [LocalPGMESWebServiceInstances_PK_InstanceId] PRIMARY KEY CLUSTERED ([Instance_Id] ASC),
    CONSTRAINT [LocalPGMESWebServiceInstances_UQ_InstanceDesc] UNIQUE NONCLUSTERED ([Instance_Desc] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LocalPGMESWebServiceInstances_IDX_InstanceDesc]
    ON [dbo].[Local_PG_MESWebService_Instances]([Instance_Desc] ASC);

