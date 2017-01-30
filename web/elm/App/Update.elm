module App.Update exposing (..)

import Task
import Process
import Time
import Keys exposing (ctrl, meta, enter)
import App.Types exposing (Coto)
import App.Model exposing (..)
import App.Messages exposing (..)
import App.Commands exposing (deleteCoto)
import Components.ConfirmModal.Update
import Components.SigninModal
import Components.ProfileModal
import Components.Timeline.Model exposing (updateCoto)
import Components.Timeline.Messages
import Components.Timeline.Update
import Components.CotoModal


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []
            
        SessionFetched (Ok session) ->
            ( { model | session = Just session }, Cmd.none )
            
        SessionFetched (Err _) ->
            ( model, Cmd.none )
        
        KeyDown key ->
            if key == ctrl.keyCode || key == meta.keyCode then
                ( { model | ctrlDown = True }, Cmd.none )
            else
                ( model, Cmd.none )

        KeyUp key ->
            if key == ctrl.keyCode || key == meta.keyCode then
                ( { model | ctrlDown = False }, Cmd.none )
            else
                ( model, Cmd.none )
                
        ConfirmModalMsg subMsg ->
            let
                ( confirmModal, cmd ) = Components.ConfirmModal.Update.update subMsg model.confirmModal
            in
                ( { model | confirmModal = confirmModal }, cmd )
            
        OpenSigninModal ->
            let
                signinModal = model.signinModal
            in
                ( { model | signinModal = { signinModal | open = True } }, Cmd.none )
            
        SigninModalMsg subMsg ->
            let
                ( signinModal, cmd ) = Components.SigninModal.update subMsg model.signinModal
            in
                ( { model | signinModal = signinModal }, Cmd.map SigninModalMsg cmd )
                
        OpenProfileModal ->
            let
                profileModal = model.profileModal
            in
                ( { model | profileModal = { profileModal | open = True } }, Cmd.none )
                
        ProfileModalMsg subMsg ->
            let
                ( profileModal, cmd ) = Components.ProfileModal.update subMsg model.profileModal
            in
                ( { model | profileModal = profileModal }, Cmd.map ProfileModalMsg cmd )
                
        CotoModalMsg subMsg ->
            let
                ( cotoModal, cmd ) = Components.CotoModal.update subMsg model.cotoModal
                confirmModal = model.confirmModal
                timeline = model.timeline
                cotos = timeline.cotos
            in
                case subMsg of
                    Components.CotoModal.ConfirmDelete message ->
                        ( { model 
                          | cotoModal = cotoModal
                          , confirmModal =
                              { confirmModal
                              | open = True
                              , message = message
                              , msgOnConfirm = 
                                  (case cotoModal.coto of
                                      Nothing -> App.Messages.NoOp
                                      Just coto -> CotoModalMsg (Components.CotoModal.Delete coto.id)
                                  )
                              }
                          }
                        , Cmd.map CotoModalMsg cmd
                        )
                        
                    Components.CotoModal.Delete cotoId  -> 
                        { model 
                        | cotoModal = cotoModal
                        , timeline =
                            { timeline
                            | cotos = cotos |> 
                                updateCoto (\c -> { c | beingDeleted = True }) cotoId
                            }
                        } !
                        [ Cmd.map CotoModalMsg cmd
                        , deleteCoto cotoId
                        , Process.sleep (1 * Time.second)
                            |> Task.andThen (\_ -> Task.succeed ())
                            |> Task.perform (\_ -> DeleteCoto cotoId)
                        ]
                        
                    _ ->
                        ( { model | cotoModal = cotoModal }, Cmd.map CotoModalMsg cmd )
            
        TimelineMsg subMsg ->
            let
                ( timeline, cmd ) = 
                    Components.Timeline.Update.update subMsg model.timeline model.ctrlDown
                cotoModal = model.cotoModal
            in
                case subMsg of
                    Components.Timeline.Messages.CotoClick cotoId ->
                        ( { model 
                          | timeline = timeline
                          , activeCotoId = (newActiveCotoId model.activeCotoId cotoId)
                          }
                        , Cmd.map TimelineMsg cmd 
                        )
                        
                    Components.Timeline.Messages.CotoOpen coto ->
                        ( { model 
                          | timeline = timeline
                          , cotoModal = 
                              { cotoModal 
                              | open = True
                              , coto = 
                                  (case coto.id of
                                      Nothing -> Nothing
                                      Just cotoId -> Just (Coto cotoId coto.content)
                                  )
                              }
                          }
                        , Cmd.map TimelineMsg cmd 
                        )

                    _ -> 
                        ( { model | timeline = timeline }, Cmd.map TimelineMsg cmd )
  
        DeleteCoto cotoId ->
            let
                timeline = model.timeline
                cotos = timeline.cotos
            in
                ( { model 
                  | timeline =
                      { timeline
                      | cotos = cotos |> (List.filter (\c -> c.id /= (Just cotoId)))
                      }
                  }
                , Cmd.none
                )
                
        CotoDeleted _ ->
            ( model, Cmd.none )


newActiveCotoId : Maybe Int -> Int -> Maybe Int
newActiveCotoId currentActiveId clickedId =
    case currentActiveId of
        Nothing -> Just clickedId
        Just activeId -> 
            if clickedId == activeId then
                Nothing
            else
                Just clickedId
            