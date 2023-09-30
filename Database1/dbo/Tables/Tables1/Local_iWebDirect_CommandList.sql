CREATE TABLE [dbo].[Local_iWebDirect_CommandList] (
    [Command_Id]              INT           IDENTITY (1, 1) NOT NULL,
    [External_Component_Name] VARCHAR (100) NOT NULL,
    [Command_Name]            VARCHAR (100) NOT NULL,
    [HTTP_Verb]               VARCHAR (10)  NOT NULL,
    [Is_Active]               BIT           NOT NULL,
    [Data_Format]             VARCHAR (10)  NULL,
    [SP_Name]                 VARCHAR (256) NOT NULL,
    [Is_Legacy]               BIT           NOT NULL,
    CONSTRAINT [LocaliWebDirectCommandList_PK_CommandId] PRIMARY KEY CLUSTERED ([Command_Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Local_iWebDirect_CommandList]
    ON [dbo].[Local_iWebDirect_CommandList]([External_Component_Name] ASC, [Command_Name] ASC, [HTTP_Verb] ASC);

