
%% $@$@$@$
#const numSteps = 3.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 sorts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#person_role = {sales, engineer, manager}.
#object_weight = {light, heavy}.
#item_surface = {hard, brittle}.
#robot_arm_type = {pneumatic, electromagnetic}.

#location = {office, library, kitchen, workshop}.
#item_status = {damaged, intact}.


#cup = {cup1}.
#book = {book1}.
#printer = {prin1}.
#item = #cup + #book + #printer.

#shelf = {shelf1, shelf2}.
#desk = {desk1}.
#table = {tab1}.
#furniture = #shelf + #desk + #table.

#object = #item + #furniture.


#robot = {rob1}.
#person = [p][0..2].
#entity = #robot + #person.	


#thing = #object + #entity.

#boolean = {true, false}.
#step = 0..numSteps.

%%%%%%%%%%
%% Fluents
%%%%%%%%%%

#inertial_fluent = loc(#thing, #location) + in_hand(#entity, #object) + status(#item, #item_status) + is_labelled(#item, #boolean).
#fluent = #inertial_fluent.


%%%%%%%%%%
%% Actions
%%%%%%%%%%

#action = move(#robot, #location) + pickup(#robot, #object) + putdown(#robot, #object) + serve(#robot, #item, #person) + affix_label(#robot,#item).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


has_role(#person, #person_role).
has_weight(#object, #object_weight).
has_surface(#item, #item_surface).
has_arm_type(#robot, #robot_arm_type).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% other predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

is_defined(#fluent).

holds(#fluent,#step).
occurs(#action,#step).

obs(#fluent, #boolean, #step).
hpd(#action, #step).

success().
goal(#step). 
something_happened(#step).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rules			        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Causal Laws %%

%% Moving changes location to target room.
holds(loc(R, L), I+1) :- occurs(move(R, L), I).

%% Picking up an object causes object to be in hand.
holds(in_hand(R, O), I+1) :- occurs(pickup(R, O), I). 

%% Putting an object down causes it to no longer be in hand.
-holds(in_hand(R, O), I+1) :- occurs(putdown(R, O), I). 

%% Serving an object to a human causes the object to be in human's hand.
holds(in_hand(P, O), I+1) :- occurs(serve(R, O, P), I).

%% Serving an object causes the object to not be in robot's hand.
-holds(in_hand(R, O), I+1) :- occurs(serve(R, O, P), I).

%% Affixing a label causes the item to be labelled.
holds(is_labelled(X, true), I+1) :- occurs(affix_label(R,X),I).

%% Putting down an item with surface 'brittle' causes item to become 'damaged'.
holds(status(X,damaged), I+1) :- occurs(putdown(R,X),I), has_surface(X,brittle).


%% State Constraints %%
%% Any object exists in only one location.
-holds(loc(Th, L2), I) :- #thing(Th), holds(loc(Th, L1), I), L1!=L2.

%% If a robot is holding an object, they have the same location.
holds(loc(O, L), I) :- holds(loc(R, L), I), holds(in_hand(R, O), I).

%% Only one entity can have an object in hand.
-holds(in_hand(E2, O), I) :- holds(in_hand(E1, O), I), E1 != E2.

%% Only one object can be held at any time.
-holds(in_hand(E, O2), I) :- holds(in_hand(E, O1), I), O1 != O2.

%% An item can only have one status.
-holds(status(X,S1), I) :- holds(status(X,S2),I), S1 != S2.

%% An item is either labelled or not labelled. 
-holds(is_labelled(X,B1),I) :- holds(is_labelled(X,B2),I), B1 != B2. 




%% All attributes of all things have have unique values.

-has_role(P,R2) :- has_role(P,R1), R1 != R2.
-has_weight(O,W2) :- has_weight(O,W1), W1 != W2.
-has_surface(X,S2) :- has_surface(X,S1), S1 != S2.
-has_arm_type(R,T2) :- has_arm_type(R,T1), T1 != T2.


%% Executability Conditions %%


%% Cannot move to a location if you are already there.
-occurs(move(R, L), I) :- holds(loc(R, L), I), not affordance_permits(move(R, L), I, 05).

%% Cannot pick up an object if you are not in the same room.
-occurs(pickup(R, O), I) :- holds(loc(R, L1), I), holds(loc(O, L2), I), L1 != L2, not affordance_permits(pickup(R, O), I, 10).

%% Cannot pick up an object if it already has it (or another one) in hand.
-occurs(pickup(R, O2), I) :- holds(in_hand(R, O1), I), not affordance_permits(pickup(R, O2), I, 15).

%% Cannot put down an object unless it is in hand...
-occurs(putdown(R, O), I) :-  not holds(in_hand(R, O), I), not affordance_permits(putdown(R, O), I, 20).

%% Cannot serve an object unless robot and human are in same location.
-occurs(serve(R, O, P), I) :- holds(loc(R, L1), I), holds(loc(P, L2), I), L1 != L2, not affordance_permits(serve(R, O, P), I, 25).

%% Cannot serve an object if it is not in its hand
-occurs(serve(R, O, P), I) :- not holds(in_hand(R, O), I), not affordance_permits(serve(R, O, P), I, 30).

%% Cannot label an item if it is not in same location.
-occurs(affix_label(R,X), I) :- holds(loc(R, L1), I), holds(loc(X, L2), I), L1 != L2, not affordance_permits(affix_label(R,X), I, 35).

%% A robot with a electromagnetic arm can't pick up a heavy object.
-occurs(pickup(R,X),I) :- has_weight(X,heavy), has_arm_type(R,electromagnetic), not affordance_permits(pickup(R,X), I, 60).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
%% Inertial axiom + CWA

%% General inertia axioms...
holds(F,I+1) :- #inertial_fluent(F),
                holds(F,I),
                not -holds(F,I+1).

-holds(F,I+1) :- #inertial_fluent(F),
                 -holds(F,I),
                 not holds(F,I+1).
                 
%% CWA for Actions...
-occurs(A,I) :- not occurs(A,I).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
%% History and initial state rules

%% Take what actually happened into account...
occurs(A,I) :- hpd(A,I).

%% Reality check axioms...
:- obs(F, true, I), -holds(F, I).
:- obs(F, false, I), holds(F, I).

is_defined(F) :- obs(F, Y, 0).
-holds(F, 0) :- #inertial_fluent(F),
		not is_defined(F), not holds(F, 0).

%% Awareness axiom...
%holds(F, 0) | -holds(F, 0) :- #inertial_fluent(F).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
%% Planning Module

%% Failure is not an option...
success :- goal(I).
:- not success. 

%% Cannot be idle while goal remains unachieved...
occurs(A, I) | -occurs(A, I) :- not goal(I). 

%% Cannot execute two actions at the same time...
:- occurs(A1,I), occurs(A2,I), A1 != A2.

something_happened(I) :- occurs(A, I).
:- not goal(I),
   not something_happened(I).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       


% Axioms for action #1, 'serve':
%%(1) "Serving an object to a salesperson causes it to be labelled." [causal law]
holds(is_labelled(X, true), I+1) :- occurs(serve(R,X,P),I), has_role(P,sales). 
%%(2) "Item cannot be served if damaged, except to an engineer." [executability condition]
-occurs(serve(R,X,P),I) :- holds(status(X,damaged),I), not has_role(P,engineer), not affordance_permits(serve(R,X,P), I, 40).
%%(3) A robot with a pneumatic arm cannot serve a brittle object [negative affordance]
-occurs(serve(R,X,P),I) :- has_surface(X,brittle), has_arm_type(R,pneumatic), not affordance_permits(serve(R,X,P), I, 45).
%%(4) "Item cannot be served if damaged, except to an engineer, UNLESS item is labelled." [positive affordance]
affordance_permits(serve(R,X,P), I, 40) :- holds(is_labelled(X,true), I).


% Axioms for action #2, 'affix_label':
%%(5) "An item which does not have surface 'hard' cannot be labelled by a robot." [executability condition]
-occurs(affix_label(R,X),I) :- not has_surface(X,hard), not affordance_permits(affix_label(R,X), I, 50).
%%(6) "An item with item_status 'damaged' cannot be labelled by a robot with a pneumatic arm." [negative affordance]
-occurs(affix_label(R,X),I) :- holds(status(X,damaged),I), has_arm_type(R,pneumatic), not affordance_permits(affix_label(R,X), I, 55).
%%(7) labelling a light object with a pneumatic arm causes it to be damaged [causal law]
holds(status(X,damaged),I+1) :- occurs(affix_label(R,X),I), has_weight(X,light), has_arm_type(R,pneumatic).
%%(8) "An item which does not have surface 'hard' cannot be labelled by a robot, UNLESS item is heavy and robot has electromagnetic arm." [positive affordance]
affordance_permits(affix_label(R,X), I, 50) :- has_arm_type(R, electromagnetic), has_weight(X, heavy).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Axioms to be discovered...

%% (*)(*)(*)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Attributes: 
%%%%%%%%%%%%%%%%%%%
%% #_#_#
holds(status(cup1, intact),0).
holds(is_labelled(cup1, false),0).
holds(status(book1, intact),0).
holds(is_labelled(book1, true),0).
holds(status(prin1, damaged),0).
holds(is_labelled(prin1, false),0).
holds(loc(cup1, library),0).
holds(loc(book1, workshop),0).
holds(loc(prin1, library),0).
holds(loc(rob1, workshop),0).
holds(loc(p0, office),0).
holds(loc(p1, library),0).
holds(loc(p2, office),0).


%%%%%%%%%%%%%%%%
%%Initial State:
%%%%%%%%%%%%%%%%
holds(loc(tab1, workshop),0).
holds(loc(shelf1, library),0).
holds(loc(shelf2, kitchen),0).
holds(loc(desk1, office),0).



%% <^^^>
has_role(p0,sales).
has_role(p1,sales).
has_role(p2,engineer).
has_arm_type(rob1, electromagnetic).
has_weight(cup1, heavy).
has_weight(book1, light).
has_weight(prin1, heavy).
has_surface(cup1, brittle).
has_surface(book1, brittle).
has_surface(prin1, brittle).


goal(I) :- holds(in_hand(P,cup1),I), #person(P).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
occurs.
%holds.
