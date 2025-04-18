import React, { useState } from 'react';
import TutorialPanel from './TutorialPanel';
import './TutorialButton.css';

const TutorialButton = () => {
	const [showTutorial, setShowTutorial] = useState(false);
	
	const handleOpenTutorial = () => {
		setShowTutorial(true);
	};
	
	const handleCloseTutorial = () => {
		setShowTutorial(false);
	};
	
	return (
		<>
			<button className="tutorial-button" onClick={handleOpenTutorial}>
				<span className="tutorial-icon">?</span>
				<span className="tutorial-text">游戏教程</span>
			</button>
			
			<TutorialPanel 
				isOpen={showTutorial} 
				onClose={handleCloseTutorial} 
			/>
		</>
	);
};

export default TutorialButton; 