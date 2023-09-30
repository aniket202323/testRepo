CREATE TABLE [dbo].[Local_MPWS_GENL_ESigActionConfig] (
    [Id]                  INT           IDENTITY (1, 1) NOT NULL,
    [PWAction]            VARCHAR (50)  NOT NULL,
    [PWFunction]          VARCHAR (50)  NOT NULL,
    [ValidUserGroup]      VARCHAR (50)  NOT NULL,
    [ESigEnabled]         BIT           CONSTRAINT [DF_Local_MPWS_ESigActions_ESigEnabled] DEFAULT ((0)) NOT NULL,
    [ESigVerifierEnabled] BIT           CONSTRAINT [DF_Local_MPWS_ESigActions_ESigVerifierEnabled] DEFAULT ((0)) NOT NULL,
    [ESigStatement]       VARCHAR (255) NOT NULL,
    [ESigGroup]           VARCHAR (50)  NOT NULL,
    [ESigVerifierGroup]   VARCHAR (50)  NOT NULL,
    CONSTRAINT [PK_Local_MPWS_ESigActions] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UC_Local_MPWS_GENL_ESigActionConfig_ActionFunction] UNIQUE NONCLUSTERED ([PWAction] ASC, [PWFunction] ASC)
);

