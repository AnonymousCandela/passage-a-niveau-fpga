library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity traffic_lights is
    Port (
	 
	 --main
	clk    : in  STD_LOGIC;         -- Horloge système (fréquence élevée)
	reset  : in  STD_LOGIC;         -- Réinitialisation
	
	 --code pin
	pin_input     : in  STD_LOGIC_VECTOR(3 downto 0); -- Entree du code PIN a 4 bits
	pin_validator : in  STD_LOGIC;                    -- pin pour la validation du code pin  
	led_system : out STD_LOGIC;                       -- led qui montre si le systeme est en mode automatique ou manuel 
	 
    --feu de signalisation    
	led0   : out STD_LOGIC;              -- Feu vert route principale
	led1   : out STD_LOGIC;              -- Feu rouge route principale
	led2   : out STD_LOGIC;              -- Feu rouge voie de fer (clignotant)
	led3   : out STD_LOGIC;              -- Feu vert voie de fer
				  
	 --afficheurs
	HEX0 : out STD_LOGIC_VECTOR(6 downto 0); -- Afficheur HEX0 pour "S,R"
	HEX1 : out STD_LOGIC_VECTOR(6 downto 0); -- Afficheur HEX1 pour "T,A"
	HEX2 : out STD_LOGIC_VECTOR(6 downto 0); -- Afficheur HEX2 pour "O,S"
	HEX3 : out STD_LOGIC_VECTOR(6 downto 0); -- Afficheur HEX3 pour "P"
	
	 -- buzzer	
	buzzer : out std_logic;            -- Signal pour le buzzer
	 --capteur dòbstacle 
	trig_obstacle : out std_logic;     -- Signal TRIG pour déclencher le capteur
	echo_obstacle : in std_logic;      -- Signal ECHO du capteur
	led_obstacle  : out std_logic;     -- Sortie pour la LED d`obstacle
		  
	 -- capteurs train entree
	trig  : out std_logic;     -- Signal TRIG pour déclencher le capteur1
	echo  : in std_logic;      -- Signal ECHO du capteur1
	trig1 : out std_logic;     -- Signal TRIG pour déclencher le capteur2
	echo1 : in std_logic;      -- Signal ECHO du capteur2
	led   : out std_logic;     -- Sortie pour la LED
			  
	  -- capteurs train sortie
	trig2 : out std_logic;     -- Signal TRIG pour déclencher le capteur1
	echo2 : in std_logic;      -- Signal ECHO du capteur1
	trig3 : out std_logic;     -- Signal TRIG pour déclencher le capteur2
	echo3 : in std_logic;      -- Signal ECHO du capteur2
	leds  : out std_logic;     -- Sortie pour la LED
			  
	 -- passage du train 
	led_train       : out STD_LOGIC ;    -- LED (indicateur du train sur le passage à niveau)
		  
	 -- control manuel 
	bar : in  STD_LOGIC;
		 
		  
	-- servomoteurs
	pwm_out : out STD_LOGIC   -- Sortie PWM pour contrôler le servomoteur  
			  
     
           );
end traffic_lights;

architecture Behavioral of traffic_lights is
   

-- Valeurs binaires pour chaque lettre
    constant LETTER_S : STD_LOGIC_VECTOR(6 downto 0) := "0010010"; -- S
    constant LETTER_T : STD_LOGIC_VECTOR(6 downto 0) := "0000111"; -- T
    constant LETTER_O : STD_LOGIC_VECTOR(6 downto 0) := "1000000"; -- O
    constant LETTER_P : STD_LOGIC_VECTOR(6 downto 0) := "0001100"; -- P
    constant LETTER_R : STD_LOGIC_VECTOR(6 downto 0) := "1001110"; -- R
    constant LETTER_A : STD_LOGIC_VECTOR(6 downto 0) := "0100000"; -- A
	 constant LETTER_l : STD_LOGIC_VECTOR(6 downto 0) := "1111111"; -- 000

-- Compteur pour créer le délai de 1 seconde
    signal counter  : integer range 0 to 50000000:=0;
    signal led_state : STD_LOGIC := '0';  								-- Etat de la LED (0 = éteint, 1 = allumé)
    
--code pin
	 signal system_active: STD_Logic := '0';
	 signal correct_pin : STD_LOGIC_VECTOR(3 downto 0):= "1010"; 	-- Code PIN correct est "1010"
	 signal mode_aut: STD_Logic      := '0';
	 
-- capteur d'obstacle 
    signal counter_obstacle      : integer := 0;          	-- Compteur pour mesurer la durée de l'impulsion ECHO 
    signal counter1_obstacle     : integer := 0;          	-- Compteur pour l'impulsion TRIG 
    signal echo_active_obstacle  : std_logic := '0';      	-- Indicateur pour savoir si l'impulsion ECHO est en cours
    signal obstacle  : std_logic := '0';   					 	-- Indicateur pour s'avoir s'il ya un obstacle
	 signal key2    : std_logic   := '0'; 
	 
-- capteurs train entree ( capteur 1 et 2 de l'entree )
    signal echo_counter_1      : integer := 0;          	-- Compteur pour mesurer la durée de l'impulsion ECHO
    signal trig_counter_1      : integer := 0;          	-- Compteur pour l'impulsion TRIG
	 signal echo_counter_2      : integer := 0;          	-- Compteur pour mesurer la durée de l'impulsion ECHO
    signal trig_counter_2      : integer := 0;          	-- Compteur pour l'impulsion TRIG
    signal echo_active  : std_logic := '0';      			-- Indicateur pour savoir si l'impulsion ECHO est en cours
	 signal echo1_active : std_logic := '0';      			-- Indicateur pour savoir si l'impulsion ECHO est en cours
	 signal detecte      : std_logic := '0';      			-- confirmr la detection par le capteurs1
	 signal detecte1     : std_logic := '0';      			-- confirmr la detection par le capteurs2 
    
	 signal train_E  : std_logic := '0';    -- Indicateur pour s'avoir s'il ya un train a l'entree
	 signal key    : std_logic := '0';       

-- capteurs train sortie
    signal echo_counter_3      : integer := 0;         	-- Compteur pour mesurer la durée de l'impulsion ECHO
    signal trig_counter_3      : integer := 0;          	-- Compteur pour l'impulsion TRIG
	 signal echo_counter_4      : integer := 0;           -- Compteur pour mesurer la durée de l'impulsion ECHO
    signal trig_counter_4      : integer := 0;          	-- Compteur pour l'impulsion TRIG
    signal echo2_active        : std_logic := '0';      	-- Indicateur pour savoir si l'impulsion ECHO est en cours
	 signal echo3_active        : std_logic := '0';      	-- Indicateur pour savoir si l'impulsion ECHO est en cours
	 signal detecte2            : std_logic := '0';      	-- confirmr la detection par le capteurs1
	 signal detecte3            : std_logic := '0';      	-- confirmr la detection par le capteurs2 
	 signal train_s             : std_logic := '0';    	-- Indicateur pour s'avoir s'il ya un train a la sortie
	 signal key3                : std_logic := '0'; 
	 
--led passage du train 
 -- de l'entree vers la sortiee
    signal train_on_road : STD_LOGIC := '0';  -- Indicateur que le train est sur le passage à niveau
    signal train_passing : STD_LOGIC := '0';  -- Indicateur que le train a traversé tout le passage
	 
 -- de la sortie vers l'entree
	 signal train_on_road1 : STD_LOGIC := '0';  -- Indicateur que le train est sur le passage à niveau
    signal train_passing1 : STD_LOGIC := '0';  -- Indicateur que le train a traversé tout le passage
	 signal train : STD_LOGIC:='0';
	  
	 signal TRAIN_S_DETECTED : STD_LOGIC := '0';
	 signal TRAIN_E_DETECTED: STD_LOGIC  := '0';
 
-- Paramètres pour la fréquence du PWM (50 Hz, période de 20 ms)
    constant PERIOD       : integer := 1000000;   -- Période de 50 Hz (20 ms)
	 
-- Paramètres pour contrôler l'angle du servomoteur
    constant MIN_PULSE_WIDTH : integer := 50000;  -- Largeur d'impulsion pour 0° (1 ms)
    constant MAX_PULSE_WIDTH : integer := 100000; -- Largeur d'impulsion pour 90° (2 ms)
   
    signal count         : integer := 0;               -- Compteur de période PWM
    signal pulse_width   : integer := MIN_PULSE_WIDTH; -- Largeur d'impulsion
	 
-- buzzer
    constant period_1s     : integer := 50_000_000;   -- 1 seconde à 50 MHz (50 millions de cycles)
    signal buzzer_out2 : std_logic := '0';   			-- État du buzzer (0: off, 1: on)
    signal counter2 : integer  := 0;  						-- Compteur pour générer un signal carré à fréquence variable (par exemple, 1 kHz)
	 signal buzzer_state : std_logic := '0';   			-- État du buzzer (0: off, 1: on)
	
	 -- Fréquence du buzzer 
    constant BUZZER_FREQ : integer := 5000;     -- Fréquence du son (en Hz)
    constant CLK_FREQ    : integer := 50000000; -- Fréquence de l'horloge FPGA (50 MHz)
    constant BUZZER_FREQ2 : integer := 100;   -- Fréquence du son (en Hz)
    -- Calculs pour la génération PWM
    constant PWM_PERIOD  : integer := CLK_FREQ / BUZZER_FREQ;
    signal pwm_counter   : integer range 0 to PWM_PERIOD - 1 := 0;
    signal pwm_signal    : STD_LOGIC := '0';

    -- Calculs pour le délai de 1 seconde
    constant ONE_SEC     : integer := CLK_FREQ; -- Nombre de cycles pour 1 seconde
    constant HALF_SEC    : integer := CLK_FREQ / 4; -- Nombre de cycles pour 0,5 seconde
    signal delay_counter : integer range 0 to ONE_SEC - 1 := 0;
    signal buzzer_enable : STD_LOGIC := '0'; -- Signal pour activer/désactiver le bip
   
     
    -- Calculs pour la génération PWM
    constant PWM_PERIOD2  : integer := CLK_FREQ / BUZZER_FREQ2;
    signal pwm_counter2   : integer range 0 to PWM_PERIOD - 1 := 0;
    signal pwm_signal2    : STD_LOGIC := '0';

    -- Durées pour les sons et les silences
    constant SOUND_DURATION : integer := CLK_FREQ / 4;  -- Durée d'un son (0,25 seconde)
    constant PAUSE_DURATION : integer := CLK_FREQ / 2;  -- Pause entre deux sons (0,5 seconde)
    constant TOTAL_CYCLE    : integer := (SOUND_DURATION + PAUSE_DURATION) * 4; -- Cycle complet (4 sons)

    signal state_counter : integer range 0 to TOTAL_CYCLE - 1 := 0;
    signal buzzer_enable2 : STD_LOGIC := '0'; -- Active ou désactive le son
	 
	
	  
-- Define an enumerated type for states
	type state_type is (auto, manuel);
-- Define an enumerated type for states

	signal state : state_type;

	
begin

--processus pour le code de changement de mode ( automatique/ manuel)
	process(pin_validator,reset )
				 begin
				
				if falling_edge(pin_validator) then
						-- Verifier si le PIN entre est correct
					 if pin_input = correct_pin then
							 if reset = '1' then
								  system_active <= '0'; 
								    else
							 -- Basculer l'etat du systeme
								  system_active <= not system_active; -- Desactiver le systeme si deja active
							 end if;
					 end if ;
				end if;
	end process;
	
	led_system <= system_active;
	mode_aut <= system_active;
	
--processus pour gerer la bariere manuellement si le mode automatique n'est pas activer
process(clk)
begin
    
            if mode_aut = '1' then
                   state <= auto;  
                  else
                   state <= manuel;   
             end if;
				 

 case state is
     when manuel =>        
            
        if BAR ='0' then
--              
					 -- retour à l'état initial "RAS"
                led0 <= '1';  -- Feu vert route principale
                led1 <= '0';  -- Feu rouge route principale
                led2 <= '1';  -- Feu rouge voie de fer
                led3 <= '0';  -- Feu vert voie de fer
                -- Affichage du mot "RAS"
                HEX3 <= LETTER_R;  -- Affiche "R" sur HEX0
                HEX2 <= LETTER_A;  -- Affiche "A" sur HEX1
                HEX1 <= LETTER_S;  -- Affiche "S" sur HEX2
					 HEX0 <= LETTER_l;  -- Éteindre tous les segments de HEX0
                
          end if;
			 if BAR ='1'  then
                   
					 led0 <= '0';  -- Feu vert route principale => rouge
                led1 <= '1';  -- Feu rouge route principale
                led2 <= '0';  -- Feu rouge voie de fer
                led3 <= '1';  -- Feu vert voie de fer
                -- Affichage du mot "STOP"
                HEX3 <= LETTER_S;  -- Affiche "S" sur HEX0
                HEX2 <= LETTER_T;  -- Affiche "T" sur HEX1
                HEX1 <= LETTER_O;  -- Affiche "O" sur HEX2
                HEX0 <= LETTER_P;  -- Affiche "P" sur HEX3
					 -- buzzer active son route
					 buzzer<= buzzer_state;
                  
          end if;
	 
     when auto =>
	    
              
		-- Processus pour gérer les feux et l'affichage
        if reset = '1' then
            -- Réinitialisation : Feu de la route principale en vert, voie de fer en rouge
            led0 <= '0';  -- Feu vert route principale
            led1 <= '0';  -- Feu rouge route principale
            led2 <= '0';  -- Feu rouge voie de fer
            led3 <= '0';  -- Feu vert voie de fer
            HEX3 <= "1111111";  -- Éteindre tous les segments de HEX3
            HEX2 <= "1111111";  -- Éteindre tous les segments de HEX2
            HEX1 <= "1111111";  -- Éteindre tous les segments de HEX1
            HEX0 <= "1111111";  -- Éteindre tous les segments de HEX0

				
        else
            if (key = '0' and key2 = '0') or (key3 = '0' and key2 = '0' )then
				    
				
                -- Si les deux clés sont appuyées (obstacle détecté et train), on affiche "STOP"
                led0 <= '0';  -- Feu vert route principale => rouge
                led1 <= '1';  -- Feu rouge route principale
                led2 <= led_state; -- Feu rouge voie de fer (clignotant)
                led3 <= '0';  -- Feu vert voie de fer
                -- Affichage du mot "STOP"
                HEX3 <= LETTER_S;  -- Affiche "S" sur HEX0
                HEX2 <= LETTER_T;  -- Affiche "T" sur HEX1
                HEX1 <= LETTER_O;  -- Affiche "O" sur HEX2
                HEX0 <= LETTER_P;  -- Affiche "P" sur HEX3
					 -- buzzer active son train 
					buzzer <= buzzer_out2;
					 
            elsif train = '1'  then 
				
                
                led0 <= '0';  -- Feu vert route principale => rouge
                led1 <= '1';  -- Feu rouge route principale
                led2 <= '0';  -- Feu rouge voie de fer
                led3 <= '1';  -- Feu vert voie de fer
                -- Affichage du mot "STOP"
                HEX3 <= LETTER_S;  -- Affiche "S" sur HEX0
                HEX2 <= LETTER_T;  -- Affiche "T" sur HEX1
                HEX1 <= LETTER_O;  -- Affiche "O" sur HEX2
                HEX0 <= LETTER_P;  -- Affiche "P" sur HEX3
					 -- buzzer active son route
					 buzzer<= buzzer_state;
					  
            else
				
                -- retour à l'état initial "RAS"
                led0 <= '1';  -- Feu vert route principale
                led1 <= '0';  -- Feu rouge route principale
                led2 <= '1';  -- Feu rouge voie de fer
                led3 <= '0';  -- Feu vert voie de fer
                -- Affichage du mot "RAS"
                HEX3 <= LETTER_R;  -- Affiche "H" sur HEX0
                HEX2 <= LETTER_A;  -- Affiche "A" sur HEX1
                HEX1 <= LETTER_S;  -- Affiche "S" sur HEX2
					 HEX0 <= LETTER_l;  -- Éteindre tous les segments de HEX0
					 
            end if;
        end if;
		 
       end case;

end process;
   
key3 <= train_s;  
key <= train_E;
key2 <= obstacle;	 
	 
-- processus pour la led du train clignotant 
process(clk,key, key2)
begin
	 
	 if rising_edge(clk) then 
		  if (key = '0' and key2 = '0') or (key3 = '0' and key2 = '0' ) then
				if (counter >= 50000000)  then
				  counter <= 0;
				  led_state <= not led_state;
				  else
				  counter <= counter+1;
				end if ;
			end if;
	 end if;

end process;

			
-- process train passe
process(clk, reset)
begin
	       
if rising_edge(clk) then
         	
		if train_s = '1' and train_E = '1' then
		  led_train <= '0';
	   end if;
         
            -- Si le capteur d'entrée détecte le train
					if train_E = '0' AND TRAIN_S_DETECTED  = '0'then
						 led_train <= '1';  -- Allumer LED (train sur le passage à niveau)
						 train_on_road <= '1';  -- Le train est sur le passage
						 train <='1';
						TRAIN_E_DETECTED <='1';
					elsif train_E = '1' and TRAIN_E_DETECTED ='1' then
						 led_train <= '1';  -- Garder LED2 allumée, car le train est toujours entre les capteurs
						 train <='1'; 
				    end if;
                       
            -- Si le capteur de sortie détecte également le train
            if train_s = '0' and train_on_road = '1' then
                train_passing <= '1';  -- Le train a passé le capteur de sortie
            end if;
            
            -- Si le capteur de sortie ne détecte plus le train
            if train_s = '1' and train_passing = '1' then
                led_train <= '0';  -- Éteindre LED2
                train_on_road <= '0';  -- Réinitialiser l'indicateur du train sur le passage
                train_passing <= '0';  -- Réinitialiser l'indicateur du train ayant traversé
					 train <='0';
					TRAIN_E_DETECTED <='0'; 
            end if;
				
				
				
				-- Si le capteur d'entrée détecte le train
					if train_s = '0' AND TRAIN_E_DETECTED ='0' then
						 led_train <= '1';  -- Allumer LED (train sur le passage à niveau)
						 train_on_road1 <= '1';  -- Le train est sur le passage
						 train <='1'; 
						 TRAIN_S_DETECTED <='1';
					elsif train_s = '1' and TRAIN_S_DETECTED = '1' then
						 led_train <= '1';  -- Garder LED2 allumée, car le train est toujours entre les capteurs
						 train <='1'; 
				    end if;
                       
            -- Si le capteur de sortie détecte également le train
            if train_E = '0' and  train_on_road1 = '1'  then
                train_passing1 <= '1';  -- Le train a passé le capteur de sortie
            end if;
            
            -- Si le capteur de sortie ne détecte plus le train
            if train_E = '1' and train_passing1 = '1' then
                led_train <= '0';  -- Éteindre LED2
                train_on_road1 <= '0';  -- Réinitialiser l'indicateur du train sur le passage
                train_passing1 <= '0';  -- Réinitialiser l'indicateur du train ayant traversé
					 train <='0'; 
					 TRAIN_S_DETECTED <= '0';
            end if;
        			
end if;
		  	  
end process;
	 
-- processus pour le capteur
process(clk, key2)
    begin
	  
        if rising_edge(clk) then
		  --capteur 1 entree
					-- Envoyer l'impulsion TRIG 
					if trig_counter_1 = 0 then
						 trig <= '1';  -- TRIG à '1' pour déclencher le capteur
					elsif trig_counter_1 = 500 then  -- 500 cycles pour générer une impulsion de 10 µs
						 trig <= '0';  -- TRIG à '0' après 10 µs
					end if;

            -- Incrémenter le compteur de TRIG
					if trig_counter_1 < 12_500_000 then  -- 12_500_000 pour répéter l'impulsion toutes les 250 ms
						 trig_counter_1 <= trig_counter_1 + 1;
					else
						 trig_counter_1 <= 0;  -- Réinitialiser après une période de 250 ms
					end if;
					
		  --capteur 2 entree	
				-- Envoyer l'impulsion TRIG
					if trig_counter_2 = 0 then
						 trig1 <= '1';  -- TRIG à '1' pour déclencher le capteur
					elsif trig_counter_2 = 500 then  -- 500 cycles pour générer une impulsion de 10 µs
						 trig1 <= '0';  -- TRIG à '0' après 10 µs
					end if;

            -- Incrémenter le compteur de TRIG
					if trig_counter_2 < 12_500_000 then  -- 12_500_000 pour répéter l'impulsion toutes les 250 ms
						 trig_counter_2 <= trig_counter_2 + 1;
					else
						 trig_counter_2 <= 0;  -- Réinitialiser après une période de 250 ms
					end if;
					
			--capteur dòbstacle
				 -- Envoyer l'impulsion TRIG
					if counter1_obstacle = 0 then
						 trig_obstacle <= '1';  -- TRIG à '1' pour déclencher le capteur
					elsif counter1_obstacle = 500 then  -- 500 cycles pour générer une impulsion de 10 µs
						 trig_obstacle <= '0';  -- TRIG à '0' après 10 µs
					end if;

            -- Incrémenter le compteur de TRIG
					if counter1_obstacle < 12_500_000 then  -- 12_500_000 pour répéter l'impulsion toutes les 250 ms
						 counter1_obstacle <= counter1_obstacle + 1;
					else
						 counter1_obstacle <= 0;  -- Réinitialiser après une période de 250 ms
					end if;
					
			 --capteur 1 sortie
            -- Envoyer l'impulsion TRIG 
					if trig_counter_3 = 0 then
						 trig2 <= '1';  -- TRIG à '1' pour déclencher le capteur
					elsif trig_counter_3 = 500 then  -- 500 cycles pour générer une impulsion de 10 µs
						 trig2 <= '0';  -- TRIG à '0' après 10 µs
					end if;

            -- Incrémenter le compteur de TRIG
					if trig_counter_3 < 12_500_000 then  -- 12_500_000 pour répéter l'impulsion toutes les 250 ms
						 trig_counter_3 <= trig_counter_3+ 1;
					else
						 trig_counter_3 <= 0;  -- Réinitialiser après une période de 250 ms
					end if;
				
		  --capteur 2 sortie	
				-- Envoyer l'impulsion TRIG
					if trig_counter_4 = 0 then
						 trig3 <= '1';  -- TRIG à '1' pour déclencher le capteur
					elsif trig_counter_4 = 500 then  -- 500 cycles pour générer une impulsion de 10 µs
						 trig3 <= '0';  -- TRIG à '0' après 10 µs
					end if;

            -- Incrémenter le compteur de TRIG
					if trig_counter_4 < 12_500_000 then  -- 12_500_000 pour répéter l'impulsion toutes les 250 ms
						 trig_counter_4 <= trig_counter_4 + 1;
					else
						 trig_counter_4 <= 0;  -- Réinitialiser après une période de 250 ms
					end if;
        end if;
		  
	-- servomoteurs
		 
	if rising_edge(clk) then
            -- Si le switch est à 1, augmenter la largeur d'impulsion (ouvrir la barrière)
		     if mode_aut = '1' then  
						if train = '1' then 
							 if  key2 = '1' then
								 if pulse_width < MAX_PULSE_WIDTH then
									  pulse_width <= pulse_width + 10;  -- Incrémenter la largeur d'impulsion pour atteindre 90°
								 end if;
							 end if;
					-- Si le switch est à 0, diminuer la largeur d'impulsion (fermer la barrière)
						else
							 if pulse_width > MIN_PULSE_WIDTH then
								  pulse_width <= pulse_width - 1000; --Réduire la largeur d'impulsion pour revenir à 0°
							 end if;
					   end if;
           end if;
		  
			  if mode_aut = '0' then  
						if bar = '1' then 
								 if  key2 = '1' then
									 if pulse_width < MAX_PULSE_WIDTH then
										  pulse_width <= pulse_width + 1000; --inémenter la largeur d'impulsion pour atteindre 90°
									 end if;
								 end if;
						-- Si le switch est à 0, diminuer la largeur d'impulsion (fermer la barrière)
						else
								 if pulse_width > MIN_PULSE_WIDTH then
									  pulse_width <= pulse_width -1000; -- Réduire la largeur d'impulsion pour revenir à 0°
								 end if;
						end if;
			  end if;
		  
	  end if;
end process;

process(clk)
    begin
	  
        if rising_edge(clk) then
		  --echo capteur 1 entree
            if echo = '1' then  -- Début de l'impulsion ECHO, commence à incrémenter le compteur
                if echo_active = '0' then
                    echo_counter_1 <= 0;  -- Réinitialiser le compteur au début de l'impulsion
                    echo_active <= '1';  -- Marquer que l'ECHO est actif
                else
                    echo_counter_1 <= echo_counter_1 + 1;  -- Incrémenter le compteur pendant que ECHO est actif
                end if;
            elsif echo = '0' and echo_active = '1' then
                -- Fin de l'impulsion ECHO, calculer la distance
                echo_active <= '0';  -- Marquer que l'ECHO est terminé
					 if (echo_counter_1 < 40000 )  then  -- Exemple de seuil basé sur le calcul de la distance
                    detecte <= '1';  -- L'objet est proche, allumer la LED
                else
                    detecte <= '0';  -- L'objet est loin, éteindre la LED
					end if;
                
            end if;
				
			-- echo capteur 2 entree	
				if echo1 = '1' then  -- Début de l'impulsion ECHO, commence à incrémenter le compteur
                if echo1_active = '0' then
                    echo_counter_2<= 0;  -- Réinitialiser le compteur au début de l'impulsion
                    echo1_active <= '1';  -- Marquer que l'ECHO est actif
                else
                    echo_counter_2<= echo_counter_2+ 1;  -- Incrémenter le compteur pendant que ECHO est actif
                end if;
            elsif echo1 = '0' and echo1_active = '1' then
                -- Fin de l'impulsion ECHO, calculer la distance
                echo1_active <= '0';  -- Marquer que l'ECHO est terminé
					 if (echo_counter_2 < 40000)  then  -- Exemple de seuil basé sur le calcul de la distance
                    detecte1 <= '1';  -- L'objet est proche, allumer la LED
                else
                    detecte1 <= '0';  -- L'objet est loin, éteindre la LED
					end if;
                
            end if;
				
			-- echo capteur d'obstacle
			   if echo_obstacle = '1' then  -- Début de l'impulsion ECHO, commence à incrémenter le compteur
                if echo_active_obstacle = '0' then
                    counter_obstacle <= 0;  -- Réinitialiser le compteur au début de l'impulsion
                    echo_active_obstacle <= '1';  -- Marquer que l'ECHO est actif
                else
                    counter_obstacle <= counter_obstacle + 1;  -- Incrémenter le compteur pendant que ECHO est actif
                end if;
            elsif echo_obstacle = '0' and echo_active_obstacle = '1' then
                -- Fin de l'impulsion ECHO, calculer la distance
                echo_active_obstacle <= '0';  -- Marquer que l'ECHO est terminé
                if counter_obstacle < 40000 then  -- Exemple de seuil basé sur le calcul de la distance
                    led_obstacle <= '1';  -- L'objet est proche, allumer la LED
						  obstacle <= '0';
                else
                    led_obstacle <= '0';  -- L'objet est loin, éteindre la LED
						  obstacle <= '1';
                end if;
            end if;
				
			--echo capteur 1 sortie
            if echo2 = '1' then  -- Début de l'impulsion ECHO, commence à incrémenter le compteur
                if echo2_active = '0' then
                    echo_counter_3 <= 0;  -- Réinitialiser le compteur au début de l'impulsion
                    echo2_active <= '1';  -- Marquer que l'ECHO est actif
                else
                    echo_counter_3 <= echo_counter_3 + 1;  -- Incrémenter le compteur pendant que ECHO est actif
                end if;
            elsif echo2 = '0' and echo2_active = '1' then
                -- Fin de l'impulsion ECHO, calculer la distance
                echo2_active <= '0';  -- Marquer que l'ECHO est terminé
					 if (echo_counter_3 < 40000 )  then  -- Exemple de seuil basé sur le calcul de la distance
                    detecte2 <= '1';  -- L'objet est proche, allumer la LED
                else
                    detecte2 <= '0';  -- L'objet est loin, éteindre la LED
					end if;
                
            end if;
				
			-- echo capteur 2 sortie	
				if echo3 = '1' then  -- Début de l'impulsion ECHO, commence à incrémenter le compteur
                if echo3_active = '0' then
                    echo_counter_4<= 0;  -- Réinitialiser le compteur au début de l'impulsion
                    echo3_active <= '1';  -- Marquer que l'ECHO est actif
                else
                    echo_counter_4<= echo_counter_4+ 1;  -- Incrémenter le compteur pendant que ECHO est actif
                end if;
            elsif echo3 = '0' and echo3_active = '1' then
                -- Fin de l'impulsion ECHO, calculer la distance
                echo3_active <= '0';  -- Marquer que l'ECHO est terminé
					 if (echo_counter_4 < 40000)  then  -- Exemple de seuil basé sur le calcul de la distance
                    detecte3 <= '1';  -- L'objet est proche, allumer la LED
                else
                    detecte3 <= '0';  -- L'objet est loin, éteindre la LED
					end if;
                
            end if;
			
			
			-- validation capteurs de train a lèntree
			
				if (detecte ='1' or detecte1 ='1')  then
                    led <= '1';  -- L'objet est proche, allumer la LED
						  train_E <= '0';
                else
                    led <= '0';  -- L'objet est loin, éteindre la LED
						  train_E <= '1';
            end if;
				
				-- validation capteurs de train a la sortie
				if (detecte2 ='1' or detecte3 ='1')  then
                    leds <= '1';  -- L'objet est proche, allumer la LED
						  train_s <= '0';
                else
                    leds <= '0';  -- L'objet est loin, éteindre la LED
						  train_s <= '1';
            end if;
       end if;
       if rising_edge(clk) then
		  
            if count < PERIOD then
               count <= count + 1;
            else
               count <= 0;
            end if;
				if count < pulse_width then
					  pwm_out <= '1';
					   
				 else
					 pwm_out <= '0';  
				 end if;
		  end if ;
end process;
	 
process(clk)
    begin
        if rising_edge(clk) then
             if counter2 = 60000 then
                    buzzer_state <= not buzzer_state;  -- Inverser l'état du buzzer à chaque moitié de période
                    counter2 <= 0;  -- Réinitialiser le compteur pour la période suivante
						  else
						  -- Incrémenter le compteur
                    counter2 <= counter2 + 1;
              end if;

          end if;
    end process;
	 
-- Génération du signal PWM pour le buzzer
    process(clk)
    begin
        if rising_edge(clk) then
            if pwm_counter = PWM_PERIOD - 1 then
                pwm_counter <= 0;
                pwm_signal <= not pwm_signal; -- Basculer le signal PWM
            else
                pwm_counter <= pwm_counter + 1;
            end if;
        end if;
    end process;

    -- Génération des bips (1 seconde ON, 0,5 seconde OFF)
    process(clk)
    begin
        if rising_edge(clk) then
            if delay_counter = ONE_SEC - 1 then
                delay_counter <= 0;
                buzzer_enable2 <= not buzzer_enable2; -- Activer/Désactiver le buzzer
            else
                delay_counter <= delay_counter + 1;
            end if;
        end if;
    end process;
	 

process(clk)
begin
    if rising_edge(clk) then
        if buzzer_enable2 = '1' then
            buzzer_out2 <= pwm_signal; -- Active le PWM
        else
            buzzer_out2 <= '0'; -- Désactive le buzzer
        end if;
    end if;
end process;

   
end Behavioral;


