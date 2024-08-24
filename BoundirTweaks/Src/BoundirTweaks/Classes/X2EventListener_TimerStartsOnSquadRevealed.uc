class X2EventListener_TimerStartsOnSquadRevealed extends X2EventListener config(GameData);

var config bool ENABLE_TIMER_STARTS_ON_SQUAD_REVEALED;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	if (!default.ENABLE_TIMER_STARTS_ON_SQUAD_REVEALED)
	{
		return Templates;
	}

	Templates.AddItem(CreateTimerStartsOnSquadRevealedListenerTemplate());

	return Templates;
}

static function CHEventListenerTemplate CreateTimerStartsOnSquadRevealedListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'TimerStartsOnSquadRevealed');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = false;
	Template.AddCHEvent('SquadConcealmentBroken', ConcealmentChanged, ELD_Immediate);
	Template.AddCHEvent('OnTacticalBeginPlay', ConcealmentChanged, ELD_Immediate);
	
	return Template;
}

static function EventListenerReturn ConcealmentChanged(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Player Player;
	local XComGameState NewGameState;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	Player = XComGameState_Player( EventData );

	`assert( Player != none );

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Concealment Change" );

	class'XComGameState_UITimer'.static.SuspendTimer( Player.bSquadIsConcealed, NewGameState );

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}
