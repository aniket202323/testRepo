CREATE TABLE [dbo].[Local_iWebServices_CommandList] (
    [Command_Id]              INT           IDENTITY (1, 1) NOT NULL,
    [External_Component_Name] VARCHAR (100) NOT NULL,
    [Command_Name]            VARCHAR (100) NOT NULL,
    [HTTP_Verb]               VARCHAR (10)  NOT NULL,
    [Is_Active]               BIT           NOT NULL,
    [Data_Format]             VARCHAR (10)  NOT NULL,
    [SP_Name]                 VARCHAR (256) NOT NULL,
    [Security_Group]          VARCHAR (50)  NULL,
    [Minimum_Access_Level]    VARCHAR (20)  NULL,
    CONSTRAINT [LocaliWebServicesCommandList_PK_CommandId] PRIMARY KEY CLUSTERED ([Command_Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Local_iWebServices_CommandList]
    ON [dbo].[Local_iWebServices_CommandList]([External_Component_Name] ASC, [Command_Name] ASC, [HTTP_Verb] ASC);

