import React, { useMemo, useRef, useEffect } from 'react';
import { CardProps } from "./type";
import { Icon } from './Icon';
import DollarHexagon from './DollarHexagon';

const Card: React.FC<CardProps> = React.memo(({ icon, text, style, yellow, selected, price, applied }) => {
  const cardStyle = useMemo(() => ({ ...style }), [style]);
  const cardRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (selected && cardRef.current) {
      cardRef.current.scrollIntoView({ behavior: "smooth", block: "center", inline: "center" });
    }
  }, [cardRef, selected]);

  return (
    <div ref={selected ? cardRef : null} className={'cards ' + (yellow ? 'yellow ' : '') + (selected ? 'cardsHover' : '')} style={cardStyle}>
      {/* Show purchased indicator in top-right corner if applied, otherwise show price */}
      {applied ? (
        <div className='card-purchased-indicator'>
          <div className='purchased-circle'>
            {Icon('check', 'sm')}
          </div>
        </div>
      ) : (
        price && (
          <div className='card-price'>
            <DollarHexagon />
            {price.toLocaleString()}
          </div>
        )
      )}
      <div className='cards-center-content'>
        {Icon(icon)}
        <p className='card-text'>
          {text}
        </p>
      </div>
    </div>
  )
});

export default Card;
